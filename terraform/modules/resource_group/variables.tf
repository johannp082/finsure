variable "name" {
  description = "Resource group name (e.g. rg-finsure-riskscore-dev)."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "tags" {
  description = "Tags to apply."
  type        = map(string)
  default     = {}
}
