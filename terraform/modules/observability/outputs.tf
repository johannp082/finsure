output "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.this.id
}

output "app_insights_connection_string" {
  description = "App Insights connection string (sensitive — feed to the app)."
  value       = azurerm_application_insights.this.connection_string
  sensitive   = true
}

output "app_insights_instrumentation_key" {
  description = "App Insights instrumentation key (sensitive)."
  value       = azurerm_application_insights.this.instrumentation_key
  sensitive   = true
}
