# Module: resource_group
# A thin wrapper so every environment creates its RG the same way.

resource "azurerm_resource_group" "this" {
  name     = var.name
  location = var.location
  tags     = var.tags
}
