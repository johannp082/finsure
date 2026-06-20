# Copy to prod.backend.hcl and fill in the storage account from the bootstrap output.
# Use with:  terraform init -backend-config=environments/prod.backend.hcl

resource_group_name  = "rg-tfstate"
storage_account_name = "stfinsuretfv9omi8" # from `terraform output` in bootstrap/
container_name       = "tfstate"
key                  = "prod.terraform.tfstate" # SEPARATE key = isolated prod state
