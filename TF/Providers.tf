########################################
# providers.tf  — AzureRM + SP (secret)
########################################

terraform {
  required_version = ">= 1.3"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.116" # pin to a recent 3.x; adjust as needed
    }
  }

  # --- OPTIONAL: Remote state in Azure Storage ---
  # Uncomment and fill these if you want remote state (recommended)
  # backend "azurerm" {
  #   resource_group_name  = "az-rim-eu2-tf"
  #   storage_account_name = "azrimeu2tfstatedev"
  #   container_name       = "tfstate"
  #   key                  = "dev/winvm.tfstate"
  # }
}

# AzureRM provider
# Auth is taken from environment variables (no use_cli):
#   ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID
provider "azurerm" {
  features {
    # Tweak as you like; sensible defaults shown
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }

  # Recommended in larger tenants to avoid surprise registrations:
  # skip_provider_registration = true

  # Optional: Default tags applied to all supported resources
  # resource_provider_registrations = "none"
  # disable_terraform_partner_id = true

  # default tags (edit/remove to your standards)
  # default_tags {
  #   tags = {
  #     environment = "dev"
  #     owner       = "iac"
  #   }
  # }
}

# (Optional) Expose information about the current principal for debugging
data "azurerm_client_config" "current" {}
output "auth_debug" {
  value = {
    tenant_id       = data.azurerm_client_config.current.tenant_id
    object_id       = data.azurerm_client_config.current.object_id
    subscription_id = data.azurerm_client_config.current.subscription_id
  }
  sensitive = false
}