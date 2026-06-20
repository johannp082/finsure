variable "log_analytics_name" {
  description = "Log Analytics workspace name (e.g. log-finsure-riskscore-dev)."
  type        = string
}

variable "app_insights_name" {
  description = "Application Insights name (e.g. appi-finsure-riskscore-dev)."
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

variable "retention_in_days" {
  description = "How long to keep logs."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags to apply."
  type        = map(string)
  default     = {}
}
