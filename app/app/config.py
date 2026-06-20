"""Application configuration.

All settings are loaded from environment variables (the "12-factor" approach).
This means the SAME code runs locally and in Azure — only the env vars change.

Locally you can place values in a `.env` file (never committed — see .gitignore).
In Azure, these are injected by the Container App / pulled from Key Vault.
"""

from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    # Tells pydantic to also read from a local .env file if present.
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    # ── Environment ────────────────────────────────────────────────
    app_env: str = "dev"          # "dev" or "prod" — used in logs/labels
    log_level: str = "INFO"       # DEBUG, INFO, WARNING, ERROR

    # ── RiskShield vendor API ──────────────────────────────────────
    riskshield_api_url: str = "https://api.riskshield.com/v1/score"
    riskshield_api_key: str | None = None  # used ONLY for local dev; in prod we read Key Vault

    # ── Resilience knobs (timeout / retry) ─────────────────────────
    http_timeout_seconds: float = 5.0   # max time to wait for RiskShield before giving up
    http_max_retries: int = 3           # how many times to retry a failed/slow call
    http_backoff_seconds: float = 0.5   # base wait between retries (grows exponentially)

    # ── Azure Key Vault (production secret storage) ────────────────
    key_vault_uri: str | None = None             # e.g. https://kv-xxxx.vault.azure.net/
    key_vault_secret_name: str = "riskshield-api-key"

    # ── Local development shortcut ─────────────────────────────────
    # When true, we DON'T call the real vendor; we return a deterministic
    # fake score. This lets anyone run/test the app with zero setup.
    use_mock: bool = False


@lru_cache
def get_settings() -> Settings:
    """Return a cached Settings instance (read env vars only once)."""
    return Settings()
