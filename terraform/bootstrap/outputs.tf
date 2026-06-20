output "resource_group_name" {
  description = "Resource group holding the state storage account."
  value       = azurerm_resource_group.tfstate.name
}

output "storage_account_name" {
  description = "Storage account name — put this in your *.backend.hcl files."
  value       = azurerm_storage_account.tfstate.name
}

output "container_name" {
  description = "Blob container that stores the state files."
  value       = azurerm_storage_container.tfstate.name
}

output "backend_config_hint" {
  description = "Copy these values into terraform/environments/<env>.backend.hcl"
  value       = <<-EOT
    resource_group_name  = "${azurerm_resource_group.tfstate.name}"
    storage_account_name = "${azurerm_storage_account.tfstate.name}"
    container_name       = "${azurerm_storage_container.tfstate.name}"
    key                  = "<env>.terraform.tfstate"
  EOT
}
