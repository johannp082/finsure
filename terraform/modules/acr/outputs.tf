output "id" {
  description = "ACR resource ID."
  value       = azurerm_container_registry.this.id
}

output "login_server" {
  description = "ACR login server (e.g. acrxxxx.azurecr.io)."
  value       = azurerm_container_registry.this.login_server
}

output "name" {
  description = "ACR name."
  value       = azurerm_container_registry.this.name
}
