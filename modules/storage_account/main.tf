terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

locals {
  base_raw   = lower(var.project_name)
  base_clean = join("", regexall("[a-z0-9]+", local.base_raw))
  base       = substr(local.base_clean, 0, 17)
}

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
  lower   = true
  numeric = true
}

resource "azurerm_storage_account" "sa" {
  name                          = "${replace(local.base, "-", "")}stg${trimspace(random_string.suffix.result)}"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  account_kind                  = "StorageV2"
  account_tier                  = var.account_tier
  account_replication_type      = var.account_replication_type
  access_tier                   = var.access_tier
  min_tls_version               = var.min_tls_version
  public_network_access_enabled = false   # all access via private endpoint
  tags                          = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

########################################
# Private DNS Zone for Blob
########################################

resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob_spoke" {
  name                  = "${var.project_name}-blob-dns-spoke"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = var.spoke_vnet_id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob_hub" {
  name                  = "${var.project_name}-blob-dns-hub"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = var.hub_vnet_id
  registration_enabled  = false
  tags                  = var.tags
}

########################################
# Private Endpoint for Blob
########################################

resource "azurerm_private_endpoint" "blob_pe" {
  name                = "${var.project_name}-blob-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.storage_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.project_name}-blob-psc"
    private_connection_resource_id = azurerm_storage_account.sa.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "blob-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob.id]
  }
}