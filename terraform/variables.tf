# ── Root input variables ───────────────────────────────────────────────────
# Per-environment values live in environments/<env>.tfvars (see the .example files).

variable "subscription_id" {
  description = "Azure subscription ID to deploy into."
  type        = string
}

variable "project" {
  description = "Project/company short name used in resource names."
  type        = string
  default     = "finsure"

  validation {
    condition     = can(regex("^[a-z0-9]{2,10}$", var.project))
    error_message = "project must be 2-10 lowercase letters/numbers."
  }
}

variable "workload" {
  description = "Workload short name used in resource names."
  type        = string
  default     = "riskscore"

  validation {
    condition     = can(regex("^[a-z0-9]{2,12}$", var.workload))
    error_message = "workload must be 2-12 lowercase letters/numbers."
  }
}

variable "environment" {
  description = "Environment name: dev or prod."
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be 'dev' or 'prod'."
  }
}

variable "location" {
  description = "Azure region (e.g. westeurope, southafricanorth)."
  type        = string
  default     = "southafricanorth"
}

# ── App / runtime configuration ─────────────────────────────────────────────

variable "use_mock" {
  description = "Run the app in mock mode (true = no real vendor needed; great for the fictional RiskShield)."
  type        = bool
  default     = true
}

variable "riskshield_api_url" {
  description = "RiskShield vendor API URL."
  type        = string
  default     = "https://api.riskshield.com/v1/score"
}

variable "log_level" {
  description = "Application log level."
  type        = string
  default     = "INFO"
}

variable "container_image" {
  description = "Container image to run. Pipeline overrides this with the ACR tag."
  type        = string
  default     = "mcr.microsoft.com/k8se/quickstart:latest"
}

# ── Sizing / scaling ────────────────────────────────────────────────────────

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

# ── Security toggles (tighten in prod) ──────────────────────────────────────

variable "external_ingress" {
  description = "Expose the app publicly."
  type        = bool
  default     = true
}

variable "kv_purge_protection" {
  description = "Enable Key Vault purge protection."
  type        = bool
  default     = false
}

variable "kv_public_network_access" {
  description = "Allow public access to Key Vault (false + private endpoint = hardened)."
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Log Analytics retention in days."
  type        = number
  default     = 30
}

variable "extra_tags" {
  description = "Additional tags merged into the default tag set."
  type        = map(string)
  default     = {}
}
