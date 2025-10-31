terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# Make a compliant base from project_name:
# - lowercase
# - remove anything not a-z0-9
# - trim so: base(17) + "stg"(3) + suffix(4) = 24 chars max
locals {
  base_raw   = lower(var.project_name)
  base_clean = regexreplace(local.base_raw, "[^a-z0-9]", "")
  base       = substr(local.base_clean, 0, 17)
}

# Short random suffix (letters only)
resource "random_string" "suffix" {
  length  = 4
  lower   = true
  upper   = false
  numeric = false
  special = false
}

resource "azurerm_storage_account" "sa" {
  name                             = "${local.base}stg${random_string.suffix.result}" # 3-24, a-z0-9 only
  resource_group_name              = var.resource_group_name
  location                         = var.location

  # Defaults to StorageV2 kind
  account_tier                     = var.account_tier             # e.g., "Standard"
  account_replication_type         = var.account_replication_type  # e.g., "LRS"
  access_tier                      = var.access_tier              # "Hot" or "Cool"

  allow_blob_public_access         = var.allow_blob_public_access
  min_tls_version                  = var.min_tls_version          # "TLS1_2" or "TLS1_3"

  public_network_access_enabled    = true

  tags = var.tags
}