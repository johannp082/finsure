variable "name" {
  description = "Key Vault name (globally unique, 3-24 chars, e.g. kv-riskscore-dev-ab12cd)."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to deploy into."
  type        = string
}

variable "tenant_id" {
  description = "Azure AD tenant ID (from azurerm_client_config)."
  type        = string
}

variable "deployer_object_id" {
  description = "Object ID of the principal running Terraform (gets Secrets Officer)."
  type        = string
}

variable "secret_name" {
  description = "Name of the RiskShield API key secret."
  type        = string
  default     = "riskshield-api-key"
}

variable "secret_initial_value" {
  description = "Placeholder value for the secret. Real value is set out-of-band."
  type        = string
  default     = "placeholder-set-the-real-key-via-cli-or-pipeline"
}

variable "purge_protection" {
  description = "Enable purge protection (recommended true in prod; false in dev for easy cleanup)."
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Allow public network access (false + private endpoint is the hardened option)."
  type        = bool
  default     = true
}

variable "network_default_action" {
  description = "Default network ACL action: Allow or Deny."
  type        = string
  default     = "Allow"
}

variable "tags" {
  description = "Tags to apply."
  type        = map(string)
  default     = {}
}
