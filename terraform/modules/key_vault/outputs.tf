output "id" {
  description = "Key Vault resource ID."
  value       = azurerm_key_vault.this.id
}

output "uri" {
  description = "Key Vault URI (e.g. https://kv-xxxx.vault.azure.net/) — passed to the app."
  value       = azurerm_key_vault.this.vault_uri
}

output "name" {
  description = "Key Vault name."
  value       = azurerm_key_vault.this.name
}

output "secret_name" {
  description = "Name of the RiskShield API key secret."
  value       = azurerm_key_vault_secret.riskshield_api_key.name
}
