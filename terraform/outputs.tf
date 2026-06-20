output "resource_group_name" {
  description = "The resource group that holds everything."
  value       = module.resource_group.name
}

output "app_url" {
  description = "Public HTTPS URL of the deployed service."
  value       = "https://${module.container_app.fqdn}"
}

output "container_app_name" {
  description = "Container App name (used by the pipeline to deploy images)."
  value       = module.container_app.name
}

output "acr_login_server" {
  description = "ACR login server (used by the pipeline to push images)."
  value       = module.acr.login_server
}

output "acr_name" {
  description = "ACR name."
  value       = module.acr.name
}

output "key_vault_name" {
  description = "Key Vault name (used to seed the real secret)."
  value       = module.key_vault.name
}

output "key_vault_uri" {
  description = "Key Vault URI."
  value       = module.key_vault.uri
}

output "managed_identity_client_id" {
  description = "Client ID of the app's managed identity."
  value       = module.identity.client_id
}
