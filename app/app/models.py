"""Request/response data models (the API "contract").
"""

from pydantic import BaseModel, Field


class ValidateRequest(BaseModel):
    """Body of POST /validate."""

    firstName: str = Field(min_length=1, max_length=100, examples=["Jane"])
    lastName: str = Field(min_length=1, max_length=100, examples=["Doe"])
    idNumber: str = Field(
        min_length=4,
        max_length=20,
        pattern=r"^[0-9]+$",  # digits only — basic input hardening
        examples=["9001011234088"],
    )


class ValidateResponse(BaseModel):
    """Successful response from POST /validate."""

    riskScore: int = Field(ge=0, le=100, examples=[72])
    riskLevel: str = Field(examples=["MEDIUM"])


class ErrorResponse(BaseModel):
    """Consistent error shape so callers can parse failures reliably."""

    error: str
    detail: str | None = None
    correlationId: str | None = None
