variable "subscription_id" {
  description = "Azure subscription ID to deploy into."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group that will hold the Terraform state storage account."
  type        = string
  default     = "rg-tfstate"
}

variable "location" {
  description = "Azure region for the state storage account."
  type        = string
  default     = "southafricanorth"
}

variable "name_prefix" {
  description = "Short lowercase prefix for the storage account name (letters/numbers only)."
  type        = string
  default     = "finsure"

  validation {
    condition     = can(regex("^[a-z0-9]{1,12}$", var.name_prefix))
    error_message = "name_prefix must be 1-12 lowercase letters/numbers."
  }
}

variable "tags" {
  description = "Tags applied to bootstrap resources."
  type        = map(string)
  default = {
    purpose   = "terraform-remote-state"
    managedBy = "terraform"
  }
}
