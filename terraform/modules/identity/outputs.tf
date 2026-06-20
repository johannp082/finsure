output "id" {
  description = "Managed identity resource ID."
  value       = azurerm_user_assigned_identity.this.id
}

output "principal_id" {
  description = "Object/principal ID — used in role assignments."
  value       = azurerm_user_assigned_identity.this.principal_id
}

output "client_id" {
  description = "Client ID — the app uses this to authenticate."
  value       = azurerm_user_assigned_identity.this.client_id
}
