  terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      # Allow the 4.x series (lockfile shows 4.49.0). Use a broad constraint for
      # compatibility with current lockfile: >=4.0, <5.0
      version = ">= 4.0, < 5.0"
    }
  }
}

# provider "azurerm" {}
  # backend "azurerm" {}

provider "azurerm" {
  features {}
  #   ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID
  # Toggle whether provider should use the local `az login` session. For CI use a service principal
  # and set `var.use_cli = false` (the workflow sets authentication via env-vars / secrets).
  use_cli = var.use_cli

  # If you prefer explicit provider configuration, you can pass subscription_id
  # and tenant_id via variables (non-sensitive). Terraform will use these if set.
  subscription_id = var.subscription_id != "" ? var.subscription_id : null
  tenant_id       = var.tenant_id != "" ? var.tenant_id : null
}

 # Default: local state (simple for free account POC)
  # To enable remote state, uncomment backend and run:
  # terraform init -backend-config="resource_group_name=az-rim-eu2-tf" \
  #   -backend-config="storage_account_name=azrimeu2tfstate-dev" \
  #   -backend-config="key=dev/winvm.tfstate"

# ---------------------------------------------------------------------------
# Example: Service Principal (environment variable) authentication for CI
#
# For non-interactive CI/CD, create a service principal and set the following
# environment variables in the runner/agent: ARM_CLIENT_ID, ARM_CLIENT_SECRET,
# ARM_TENANT_ID, ARM_SUBSCRIPTION_ID. The azurerm provider will pick them up
# automatically. You can optionally set subscription_id or tenant_id in the
# provider or pass them via variables.
#
# Example (commented) provider block using env vars / explicit fields:
#
# provider "azurerm" {
#   features {}
#
#   # If you set the following environment variables, the provider will use them:
#   #   ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID
#
#   # Optional: explicitly pin a subscription or tenant from variables
#   # subscription_id = var.subscription_id
#   # tenant_id       = var.tenant_id
#   # client_id       = var.client_id
#   # client_secret   = var.client_secret
#
#   # When using env-var auth, prefer not to set `use_cli = true`.
# }
# ---------------------------------------------------------------------------