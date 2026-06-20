"""FastAPI application entry point.

Wires together config, logging, the RiskShield client and the HTTP endpoints.
"""

import time
import uuid
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

from . import __version__
from .config import get_settings
from .logging_config import (
    configure_logging,
    correlation_id_ctx,
    get_logger,
    log_with_fields,
)
from .models import ErrorResponse, ValidateRequest, ValidateResponse
from .riskshield_client import RiskShieldClient, RiskShieldError
from .secrets import SecretResolutionError, resolve_api_key

logger = get_logger("app.main")

CORRELATION_HEADER = "X-Correlation-ID"


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Runs once at startup (and shutdown). Resolve config + secrets early so
    the app fails fast with a clear error if something is misconfigured."""
    settings = get_settings()
    configure_logging(settings.log_level)
    logger.info("Starting service v%s in env=%s", __version__, settings.app_env)

    api_key = resolve_api_key(settings)
    app.state.settings = settings
    app.state.client = RiskShieldClient(settings, api_key)
    yield
    logger.info("Shutting down service")


app = FastAPI(
    title="Vendor Payment Risk Scoring Integration",
    version=__version__,
    lifespan=lifespan,
)


@app.middleware("http")
async def correlation_and_timing(request: Request, call_next):
    """Assign a correlation ID to every request and log its timing."""
    correlation_id = request.headers.get(CORRELATION_HEADER) or str(uuid.uuid4())
    correlation_id_ctx.set(correlation_id)

    start = time.perf_counter()
    response = await call_next(request)
    duration_ms = round((time.perf_counter() - start) * 1000, 1)

    response.headers[CORRELATION_HEADER] = correlation_id
    log_with_fields(
        logger,
        20,  # logging.INFO
        "request_completed",
        method=request.method,
        path=request.url.path,
        status=response.status_code,
        durationMs=duration_ms,
    )
    return response


@app.get("/health", tags=["ops"])
async def health():
    """Liveness probe used by Docker/Azure. Cheap and dependency-free."""
    return {"status": "ok", "version": __version__}


@app.post(
    "/validate",
    response_model=ValidateResponse,
    responses={502: {"model": ErrorResponse}, 504: {"model": ErrorResponse}},
    tags=["risk"],
)
async def validate(payload: ValidateRequest, request: Request):
    """Validate an applicant against RiskShield and return their risk score."""
    client: RiskShieldClient = request.app.state.client
    correlation_id = correlation_id_ctx.get()

    log_with_fields(logger, 20, "validate_requested", idLength=len(payload.idNumber))
    result = await client.score(payload, correlation_id)
    log_with_fields(
        logger, 20, "validate_succeeded",
        riskScore=result.riskScore, riskLevel=result.riskLevel,
    )
    return result


# ── Error handlers: return consistent JSON, never leak internals ──────────

@app.exception_handler(RiskShieldError)
async def handle_riskshield_error(request: Request, exc: RiskShieldError):
    correlation_id = correlation_id_ctx.get()
    logger.error("RiskShield call failed: %s", exc)
    return JSONResponse(
        status_code=exc.status_code,
        content=ErrorResponse(
            error="risk_provider_error",
            detail=str(exc),
            correlationId=correlation_id,
        ).model_dump(),
    )


@app.exception_handler(SecretResolutionError)
async def handle_secret_error(request: Request, exc: SecretResolutionError):
    correlation_id = correlation_id_ctx.get()
    logger.error("Secret resolution failed: %s", exc)
    return JSONResponse(
        status_code=500,
        content=ErrorResponse(
            error="configuration_error",
            detail="Service is misconfigured",
            correlationId=correlation_id,
        ).model_dump(),
    )
