# Module: observability
# Central logging (Log Analytics) + app telemetry (Application Insights).

resource "azurerm_log_analytics_workspace" "this" {
  name                = var.log_analytics_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018" # pay-per-GB, standard choice
  retention_in_days   = var.retention_in_days
  tags                = var.tags
}

resource "azurerm_application_insights" "this" {
  name                = var.app_insights_name
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "web"
  # Workspace-based App Insights (the modern, required mode) stores data in the
  # Log Analytics workspace above instead of a separate classic store.
  workspace_id = azurerm_log_analytics_workspace.this.id
  tags         = var.tags
}
