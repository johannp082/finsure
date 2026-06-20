output "fqdn" {
  description = "Public hostname of the app (https://<fqdn>)."
  value       = azurerm_container_app.this.ingress[0].fqdn
}

output "name" {
  description = "Container App name."
  value       = azurerm_container_app.this.name
}

output "environment_id" {
  description = "Container App Environment resource ID."
  value       = azurerm_container_app_environment.this.id
}
