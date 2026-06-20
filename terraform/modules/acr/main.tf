# Module: acr (Azure Container Registry)
# Private registry for our Docker images.

resource "azurerm_container_registry" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku

  # SECURITY: disable the built-in admin username/password. We authenticate with
  # Managed Identity (AcrPull role) instead, so there are no static credentials.
  admin_enabled = false

  tags = var.tags
}
