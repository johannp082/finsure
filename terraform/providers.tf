terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
  }

  # Remote state in Azure Storage. Values are supplied at init time via
  # -backend-config=environments/<env>.backend.hcl (kept out of source code so
  # the same config works for dev AND prod).
  backend "azurerm" {}
}

provider "azurerm" {
  features {
    key_vault {
      # In dev we want `terraform destroy` to fully remove vaults.
      purge_soft_delete_on_destroy = true
    }
  }
  subscription_id = var.subscription_id
}
