variable "name" {
  description = "ACR name (globally unique, alphanumeric only, e.g. acrfinsureriskscoredev123)."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to deploy into."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "sku" {
  description = "ACR SKU: Basic, Standard, or Premium (Premium needed for private endpoints)."
  type        = string
  default     = "Standard"
}

variable "tags" {
  description = "Tags to apply."
  type        = map(string)
  default     = {}
}
