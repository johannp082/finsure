"""Structured (JSON) logging with per-request correlation IDs.

Why JSON? Azure Log Analytics / Application Insights can index and query
structured fields. Why correlation IDs? They let you trace a single request
across every log line it produces.
"""

import json
import logging
import sys
from contextvars import ContextVar

# A "context variable" safely stores the current request's correlation ID,
# even when many requests are handled concurrently.
correlation_id_ctx: ContextVar[str] = ContextVar("correlation_id", default="-")


class JsonFormatter(logging.Formatter):
    """Render each log record as a single JSON line."""

    def format(self, record: logging.LogRecord) -> str:
        payload = {
            "timestamp": self.formatTime(record, "%Y-%m-%dT%H:%M:%S%z"),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "correlationId": correlation_id_ctx.get(),
        }
        # Include any extra structured fields passed via logger.info(..., extra={...}).
        if hasattr(record, "extra_fields") and isinstance(record.extra_fields, dict):
            payload.update(record.extra_fields)
        # Include exception details if present.
        if record.exc_info:
            payload["exception"] = self.formatException(record.exc_info)
        return json.dumps(payload)


def configure_logging(level: str = "INFO") -> None:
    """Set up root logging to emit JSON to stdout (containers log to stdout)."""
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(JsonFormatter())

    root = logging.getLogger()
    root.handlers.clear()
    root.addHandler(handler)
    root.setLevel(level.upper())

    # Quiet down noisy third-party loggers a bit.
    logging.getLogger("azure").setLevel(logging.WARNING)
    logging.getLogger("uvicorn.access").setLevel(logging.WARNING)


def get_logger(name: str) -> logging.Logger:
    return logging.getLogger(name)


def log_with_fields(logger: logging.Logger, level: int, message: str, **fields) -> None:
    """Helper to log a message with extra structured fields."""
    logger.log(level, message, extra={"extra_fields": fields})
