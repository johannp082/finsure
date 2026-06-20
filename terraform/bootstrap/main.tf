# ──────────────────────────────────────────────────────────────────────────
# BOOTSTRAP: creates the Azure Storage account used to hold Terraform "remote
# state" for all environments.
#
# WHY a separate step? Terraform needs somewhere to store its state file. But
# that somewhere (a storage account) must itself be created first. This is a
# chicken-and-egg problem. So we create it ONCE here using LOCAL state, then
# every other config uses this storage account as its backend.
#
# Run this once per subscription. See terraform/bootstrap/README.md.
# ──────────────────────────────────────────────────────────────────────────

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
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# A short random suffix makes the storage account name globally unique.
resource "random_string" "suffix" {
  length  = 6
  lower   = true
  upper   = false
  numeric = true
  special = false
}

resource "azurerm_resource_group" "tfstate" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_storage_account" "tfstate" {
  name                     = "st${var.name_prefix}tf${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = azurerm_resource_group.tfstate.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # ── Security hardening ──────────────────────────────────────────
  min_tls_version                 = "TLS1_2" # reject old, insecure TLS
  https_traffic_only_enabled      = true     # no plain HTTP
  allow_nested_items_to_be_public = false    # no accidental public blobs
  shared_access_key_enabled       = true     # backend uses a key/AD; keep on for simplicity

  blob_properties {
    versioning_enabled = true # keep history of state files
    delete_retention_policy {
      days = 7 # recover deleted state for 7 days
    }
  }

  tags = var.tags
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private" # state is sensitive — never public
}
