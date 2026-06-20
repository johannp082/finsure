variable "name" {
  description = "Container App name (e.g. ca-finsure-riskscore-dev)."
  type        = string
}

variable "environment_name" {
  description = "Container App Environment name (e.g. cae-finsure-riskscore-dev)."
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

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for container logs."
  type        = string
}

variable "identity_id" {
  description = "User-assigned Managed Identity resource ID."
  type        = string
}

variable "acr_login_server" {
  description = "ACR login server for pulling images."
  type        = string
}

variable "container_image" {
  description = "Image to run. First apply uses a placeholder; pipeline deploys the real tag."
  type        = string
  default     = "mcr.microsoft.com/k8se/quickstart:latest"
}

variable "target_port" {
  description = "Port the container listens on."
  type        = number
  default     = 8000
}

variable "external_ingress" {
  description = "Expose publicly (true) or internal-only (false)."
  type        = bool
  default     = true
}

variable "min_replicas" {
  description = "Minimum replicas (0 = scale to zero when idle)."
  type        = number
  default     = 0
}

variable "max_replicas" {
  description = "Maximum replicas."
  type        = number
  default     = 3
}

variable "cpu" {
  description = "vCPU per replica (e.g. 0.5)."
  type        = number
  default     = 0.5
}

variable "memory" {
  description = "Memory per replica (must pair with cpu, e.g. 1Gi for 0.5 cpu)."
  type        = string
  default     = "1Gi"
}

variable "env_vars" {
  description = "Map of environment variables for the container."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags to apply."
  type        = map(string)
  default     = {}
}
