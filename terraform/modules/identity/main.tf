# Module: identity
# A user-assigned Managed Identity that the Container App runs as.
# We grant THIS identity permission to pull from ACR and read Key Vault secrets.

resource "azurerm_user_assigned_identity" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}
