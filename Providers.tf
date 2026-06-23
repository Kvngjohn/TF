terraform {
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
