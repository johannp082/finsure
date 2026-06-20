# Copy to prod.tfvars and fill in your subscription ID.
# Apply with:  terraform apply -var-file=environments/prod.tfvars

subscription_id = "16aa09a3-b347-4267-aa41-5ec40aae2533"

project     = "finsure"
workload    = "riskscore"
environment = "prod"
location    = "southafricanorth"

# In a real prod you would point at the real vendor and set use_mock=false.
# Because RiskShield is fictional, we keep mock=true so smoke tests pass.
use_mock           = true
riskshield_api_url = "https://api.riskshield.com/v1/score"
log_level          = "INFO"

# Always keep at least one replica warm in prod for low latency.
min_replicas = 1
max_replicas = 5

# Hardened security posture for prod.
external_ingress         = true   # set false + add a private endpoint to fully lock down
kv_purge_protection      = true   # cannot be undone — protects against secret deletion
kv_public_network_access = true   # set false + private endpoint for the hardened option
log_retention_days       = 90
