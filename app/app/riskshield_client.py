"""Client for the RiskShield vendor API, with production-grade resilience.

Features:
  - Timeout on every call (config.http_timeout_seconds).
  - Automatic retry with exponential backoff on transient failures only.
  - Correlation ID propagated to the vendor for end-to-end tracing.
  - A built-in mock so the service runs with zero external dependencies.
"""

import logging

import httpx
from tenacity import (
    retry,
    retry_if_exception_type,
    stop_after_attempt,
    wait_exponential,
)

from .config import Settings
from .models import ValidateRequest, ValidateResponse

logger = logging.getLogger(__name__)


class RiskShieldError(Exception):
    """Raised when RiskShield cannot return a usable response."""

    def __init__(self, message: str, *, status_code: int = 502):
        super().__init__(message)
        self.status_code = status_code


class _RetryableError(Exception):
    """Internal marker for failures that are safe to retry."""


def _risk_level_from_score(score: int) -> str:
    if score >= 70:
        return "HIGH"
    if score >= 40:
        return "MEDIUM"
    return "LOW"


def _mock_score(req: ValidateRequest) -> ValidateResponse:
    """Deterministic fake score so the app works without the real vendor.

    Uses the last two digits of the ID number to produce a stable 0-99 score.
    """
    score = int(req.idNumber[-2:]) % 100
    return ValidateResponse(riskScore=score, riskLevel=_risk_level_from_score(score))


class RiskShieldClient:
    def __init__(self, settings: Settings, api_key: str):
        self._settings = settings
        self._api_key = api_key

    async def score(self, req: ValidateRequest, correlation_id: str) -> ValidateResponse:
        if self._settings.use_mock:
            logger.info("RiskShield mock mode: returning deterministic score")
            return _mock_score(req)

        return await self._score_with_retry(req, correlation_id)

    async def _score_with_retry(
        self, req: ValidateRequest, correlation_id: str
    ) -> ValidateResponse:
        # tenacity decorator built dynamically so it can read config values.
        retryer = retry(
            reraise=True,
            stop=stop_after_attempt(self._settings.http_max_retries),
            wait=wait_exponential(
                multiplier=self._settings.http_backoff_seconds, min=0.1, max=10
            ),
            retry=retry_if_exception_type(_RetryableError),
        )
        try:
            return await retryer(self._call_once)(req, correlation_id)
        except _RetryableError as exc:
            # Exhausted retries on a transient error -> 504 Gateway Timeout.
            raise RiskShieldError(str(exc), status_code=504) from exc

    async def _call_once(
        self, req: ValidateRequest, correlation_id: str
    ) -> ValidateResponse:
        headers = {
            "x-api-key": self._api_key,         # vendor authentication
            "X-Correlation-ID": correlation_id,  # end-to-end tracing
            "Content-Type": "application/json",
        }
        timeout = httpx.Timeout(self._settings.http_timeout_seconds)
        try:
            async with httpx.AsyncClient(timeout=timeout) as client:
                resp = await client.post(
                    self._settings.riskshield_api_url,
                    json=req.model_dump(),
                    headers=headers,
                )
        except (httpx.TimeoutException, httpx.TransportError) as exc:
            # Network/timeout problems are transient -> retry.
            logger.warning("RiskShield transient error: %s", type(exc).__name__)
            raise _RetryableError(f"network error: {exc}") from exc

        # 5xx = vendor server problem -> retry. 4xx = our problem -> do NOT retry.
        if resp.status_code >= 500:
            logger.warning("RiskShield 5xx: %s", resp.status_code)
            raise _RetryableError(f"vendor returned {resp.status_code}")
        if resp.status_code >= 400:
            raise RiskShieldError(
                f"RiskShield rejected the request ({resp.status_code})",
                status_code=502,
            )

        data = resp.json()
        score = int(data["riskScore"])
        level = data.get("riskLevel") or _risk_level_from_score(score)
        return ValidateResponse(riskScore=score, riskLevel=level)
