# Copy to dev.tfvars and fill in your subscription ID.
# Apply with:  terraform apply -var-file=environments/dev.tfvars

subscription_id = "16aa09a3-b347-4267-aa41-5ec40aae2533"

project     = "finsure"
workload    = "riskscore"
environment = "dev"
location    = "southafricanorth"

# Dev runs in mock mode so the (fictional) RiskShield vendor isn't needed.
use_mock  = true
log_level = "INFO"

# Cost-friendly for a trial subscription: scale to zero when idle.
min_replicas = 0
max_replicas = 2

# Relaxed security in dev for convenience (tighten in prod).
external_ingress         = true
kv_purge_protection      = false
kv_public_network_access = true
log_retention_days       = 30
