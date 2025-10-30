terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# Create a compliant, globally-unique storage account name
# <project trimmed/lower> + "stg" + 4 random lower letters
locals {
  base = substr(lower(replace(var.project_name, "[^a-z0-9]", "")), 0, 17)
}

resource "random_string" "suffix" {
  length  = 4
  lower   = true
  upper   = false
  special = false
}

resource "azurerm_storage_account" "sa" {
  name                          = "${local.base}stg${random_string.suffix.result}" # 3-24, lower only
  resource_group_name           = var.resource_group_name
  location                      = var.location
  account_tier                  = var.account_tier
  account_replication_type      = var.account_replication_type
  access_tier                   = var.access_tier
  min_tls_version               = var.min_tls_version
  public_network_access_enabled = true

  tags = var.tags
}
