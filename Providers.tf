# TF/providers.tf

terraform {
  required_version = ">= 1.3"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      # Kept your v3 constraint per your note; v3 natively supports Service Principal variables
      version = "~> 3.117" 
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Configures Azure Blob Storage to hold your remote state file safely
  backend "azurerm" {
    resource_group_name  = "Rg-Az-rim-01"
    storage_account_name = "azstreus2prod01"
    container_name       = "tfprod01"
    key                  = "prod.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}
