# Terraform Remote State Bootstrap

This creates the Azure Storage account that holds Terraform **remote state** for
all environments. Run it **once** per subscription, before the main config.

## Why this exists

Terraform stores a "state file" describing what it created. By default that file
sits on your laptop — which is risky (no locking, easy to lose, may hold secrets).
We instead store it in Azure Storage: encrypted, shared, versioned, and locked so
two people can't corrupt it. But the storage account itself must be created first,
hence this separate bootstrap step (it uses local state, just this once).

## Steps

```powershell
# 1. Log in and select your subscription
az login
az account show --query id -o tsv   # copy this subscription ID

cd terraform/bootstrap

# 2. Initialise (downloads providers)
terraform init

# 3. Create the state storage (replace with your subscription ID)
terraform apply -var="subscription_id=YOUR_SUB_ID"

# 4. Note the outputs — you'll paste them into the backend.hcl files
terraform output
```

## Next

Copy the `storage_account_name` from the output into
`terraform/environments/dev.backend.hcl` and `prod.backend.hcl`, then proceed to
the main config (see `docs/03-terraform.md`).
