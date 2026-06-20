# Module: key_vault
# Secure storage for the RiskShield API key. Access is governed by Azure RBAC.

terraform {
  required_providers {
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
  }
}

resource "azurerm_key_vault" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = var.tenant_id
  sku_name            = "standard"

  # ── Security settings ───────────────────────────────────────────
  rbac_authorization_enabled    = true # use Azure RBAC, not access policies
  purge_protection_enabled      = var.purge_protection
  soft_delete_retention_days    = 7 # recover deleted secrets within 7 days
  public_network_access_enabled = var.public_network_access_enabled

  network_acls {
    # "Deny" + bypass AzureServices is the secure default. For the assessment we
    # default to "Allow" so you can seed the secret from your machine/pipeline,
    # but this is overridable per environment (prod should tighten this).
    default_action = var.network_default_action
    bypass         = "AzureServices"
  }

  tags = var.tags
}

# Grant the CURRENT deployer (you / the pipeline SP) permission to create secrets.
# Without this, RBAC would block Terraform from writing the secret below.
resource "azurerm_role_assignment" "deployer_secrets_officer" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.deployer_object_id
}

# RBAC role assignments take a few seconds to propagate. Wait before writing.
resource "time_sleep" "wait_for_rbac" {
  depends_on      = [azurerm_role_assignment.deployer_secrets_officer]
  create_duration = "30s"
}

# Seed the secret with a placeholder. The REAL value is set out-of-band (Azure
# CLI or pipeline) so it never lives in Terraform state. lifecycle ignore_changes
# means Terraform won't overwrite the real value on future applies.
resource "azurerm_key_vault_secret" "riskshield_api_key" {
  name         = var.secret_name
  value        = var.secret_initial_value
  key_vault_id = azurerm_key_vault.this.id

  depends_on = [time_sleep.wait_for_rbac]

  lifecycle {
    ignore_changes = [value]
  }
}
