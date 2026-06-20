"""Resolves the RiskShield API key from the most secure source available.

Resolution order:
  1. use_mock=True            -> no key needed (local/testing).
  2. key_vault_uri is set     -> fetch from Azure Key Vault via Managed Identity.
  3. riskshield_api_key (env) -> local development fallback only.

NEVER hardcode the key. NEVER log it.

NOTE: this module is intentionally NOT named `secrets.py` to avoid shadowing the
Python standard-library `secrets` module.
"""

import logging

from .config import Settings

logger = logging.getLogger(__name__)


class SecretResolutionError(RuntimeError):
    """Raised when no API key can be obtained from any source."""


def resolve_api_key(settings: Settings) -> str:
    # 1) Mock mode needs no real secret.
    if settings.use_mock:
        return "mock-key-not-used"

    # 2) Production path: Azure Key Vault + Managed Identity.
    if settings.key_vault_uri:
        try:
            # Imported lazily so local/mock runs don't require Azure libs at import time.
            from azure.identity import DefaultAzureCredential
            from azure.keyvault.secrets import SecretClient

            # DefaultAzureCredential automatically uses the Container App's
            # Managed Identity in Azure (and your `az login` locally).
            credential = DefaultAzureCredential()
            client = SecretClient(vault_url=settings.key_vault_uri, credential=credential)
            secret = client.get_secret(settings.key_vault_secret_name)
            logger.info("Retrieved RiskShield API key from Key Vault")
            return secret.value
        except Exception as exc:  # noqa: BLE001 - surface a clear, safe error
            raise SecretResolutionError(
                "Failed to read API key from Key Vault"
            ) from exc

    # 3) Local development fallback.
    if settings.riskshield_api_key:
        logger.warning("Using RiskShield API key from environment (local dev only)")
        return settings.riskshield_api_key

    raise SecretResolutionError(
        "No RiskShield API key available. Set USE_MOCK=true, KEY_VAULT_URI, "
        "or RISKSHIELD_API_KEY."
    )
