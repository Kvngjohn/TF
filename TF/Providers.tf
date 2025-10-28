########################################
# providers.tf — AzureRM + SP (secret)
########################################

terraform {
  required_version = ">= 1.3"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.117"
    }
  }
}

# Define the provider block once
provider "azurerm" {
  features {}
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
