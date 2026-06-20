# ──────────────────────────────────────────────────────────────────────────
# Root configuration: composes the modules into a full environment.
# ──────────────────────────────────────────────────────────────────────────

data "azurerm_client_config" "current" {}

# Random suffix for globally-unique names (ACR, Key Vault).
resource "random_string" "suffix" {
  length  = 6
  lower   = true
  upper   = false
  numeric = true
  special = false
}

locals {
  base    = "${var.project}-${var.workload}-${var.environment}" # finsure-riskscore-dev
  compact = "${var.project}${var.workload}${var.environment}"   # finsureriskscoredev

  tags = merge({
    project     = var.project
    workload    = var.workload
    environment = var.environment
    managedBy   = "terraform"
  }, var.extra_tags)

  # Resource names following Azure CAF conventions.
  names = {
    resource_group = "rg-${local.base}"
    log_analytics  = "log-${local.base}"
    app_insights   = "appi-${local.base}"
    acr            = "acr${local.compact}${random_string.suffix.result}"
    key_vault      = "kv-${substr(local.compact, 0, 11)}-${random_string.suffix.result}"
    identity       = "id-${local.base}"
    container_env  = "cae-${local.base}"
    container_app  = "ca-${local.base}"
  }
}

module "resource_group" {
  source   = "./modules/resource_group"
  name     = local.names.resource_group
  location = var.location
  tags     = local.tags
}

module "observability" {
  source              = "./modules/observability"
  log_analytics_name  = local.names.log_analytics
  app_insights_name   = local.names.app_insights
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  retention_in_days   = var.log_retention_days
  tags                = local.tags
}

module "acr" {
  source              = "./modules/acr"
  name                = local.names.acr
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  sku                 = "Standard"
  tags                = local.tags
}

module "identity" {
  source              = "./modules/identity"
  name                = local.names.identity
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  tags                = local.tags
}

module "key_vault" {
  source                        = "./modules/key_vault"
  name                          = local.names.key_vault
  location                      = module.resource_group.location
  resource_group_name           = module.resource_group.name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  deployer_object_id            = data.azurerm_client_config.current.object_id
  purge_protection              = var.kv_purge_protection
  public_network_access_enabled = var.kv_public_network_access
  tags                          = local.tags
}

# ── Role assignments (least privilege) ──────────────────────────────────────
# The app's identity may PULL images from ACR...
resource "azurerm_role_assignment" "acr_pull" {
  scope                = module.acr.id
  role_definition_name = "AcrPull"
  principal_id         = module.identity.principal_id
}

# ...and READ secrets from Key Vault. Nothing more.
resource "azurerm_role_assignment" "kv_secrets_user" {
  scope                = module.key_vault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.identity.principal_id
}

# ── Diagnostic logging: send Key Vault audit logs to Log Analytics ──────────
resource "azurerm_monitor_diagnostic_setting" "key_vault" {
  name                       = "diag-to-law"
  target_resource_id         = module.key_vault.id
  log_analytics_workspace_id = module.observability.log_analytics_workspace_id

  enabled_log {
    category = "AuditEvent"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

module "container_app" {
  source                     = "./modules/container_app"
  name                       = local.names.container_app
  environment_name           = local.names.container_env
  location                   = module.resource_group.location
  resource_group_name        = module.resource_group.name
  log_analytics_workspace_id = module.observability.log_analytics_workspace_id
  identity_id                = module.identity.id
  acr_login_server           = module.acr.login_server
  container_image            = var.container_image
  external_ingress           = var.external_ingress
  min_replicas               = var.min_replicas
  max_replicas               = var.max_replicas

  env_vars = {
    APP_ENV               = var.environment
    LOG_LEVEL             = var.log_level
    USE_MOCK              = tostring(var.use_mock)
    RISKSHIELD_API_URL    = var.riskshield_api_url
    KEY_VAULT_URI         = module.key_vault.uri
    KEY_VAULT_SECRET_NAME = module.key_vault.secret_name
  }

  tags = local.tags

  # Ensure the identity can pull/read before the app starts.
  depends_on = [
    azurerm_role_assignment.acr_pull,
    azurerm_role_assignment.kv_secrets_user,
  ]
}
