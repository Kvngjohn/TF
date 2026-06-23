########################################
# ROOT main.tf — Hub-Spoke Architecture
#
# Internet
#   → Azure Front Door Premium (global WAF/DDoS + CDN)
#     → App Gateway WAF_v2 (regional L7 LB + OWASP)
#       → 3 Windows VMs in Spoke App Subnet
#
# Egress: Spoke UDR → Azure Firewall in Hub (force-tunnel)
# Management: Azure Bastion in Hub (no VM public IPs needed)
# SQL + Storage: private endpoints only (public_network_access disabled)
# Backups: Recovery Services Vault (VMs), built-in SQL LTR
########################################

locals {
  vm_names = [
    coalesce(var.vm_name_1, "${var.project_name}-winvm01"),
    coalesce(var.vm_name_2, "${var.project_name}-winvm02"),
    coalesce(var.vm_name_3, "${var.project_name}-winvm03"),
  ]
  vm_keys = ["vm01", "vm02", "vm03"]
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.project_name}-rg"
  location = var.location
  tags     = var.tags
}

# Log Analytics workspace — shared sink for all diagnostics and DCR
resource "azurerm_log_analytics_workspace" "law" {
  name                = "${var.project_name}-law"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 90
  tags                = var.tags
}

# ── 1. Hub Networking: Hub VNet + Azure Firewall + Bastion + UDR
module "hub_networking" {
  source = "./modules/hub_networking"

  project_name               = var.project_name
  location                   = var.location
  resource_group_name        = azurerm_resource_group.rg.name
  tags                       = var.tags
  hub_address_space          = var.hub_address_space
  firewall_subnet_prefix     = var.firewall_subnet_prefix
  hub_mgmt_subnet_prefix     = var.hub_mgmt_subnet_prefix
  bastion_subnet_prefix      = var.bastion_subnet_prefix
  spoke_address_space        = var.spoke_address_space
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
}

# ── 2. Spoke Networking: App/Data/Storage/AppGW subnets + VNet Peering
module "spoke_networking" {
  source = "./modules/spoke_networking"

  project_name          = var.project_name
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg.name
  tags                  = var.tags
  spoke_address_space   = var.spoke_address_space
  app_subnet_prefix     = var.app_subnet_prefix
  data_subnet_prefix    = var.data_subnet_prefix
  storage_subnet_prefix = var.storage_subnet_prefix
  appgw_subnet_prefix   = var.appgw_subnet_prefix
  allow_rdp_from_cidr   = var.allow_rdp_from_cidr
  hub_vnet_id           = module.hub_networking.hub_vnet_id
  hub_vnet_name         = module.hub_networking.hub_vnet_name
  spoke_udr_id          = module.hub_networking.spoke_udr_id
}

module "windows_vm" {
  count  = 3
  source = "./modules/windows_vm"

  vm_name             = local.vm_names[count.index]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  vm_size             = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  alert_email         = var.alert_email   
  subnet_id           = module.spoke_networking.app_subnet_id
  create_public_ip    = false
  tags                = var.tags
}

# ── 4. Application Gateway WAF_v2 (regional load balancer in front of VMs)
module "app_gateway" {
  source = "./modules/app_gateway"

  project_name        = var.project_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
  appgw_subnet_id     = module.spoke_networking.appgw_subnet_id
  vm_backend_ips      = [for vm in module.windows_vm : vm.private_ip]
}

# ── 5. Storage Account (public access off, blob private endpoint)
module "storage_account" {
  source = "./modules/storage_account"

  project_name             = var.project_name
  location                 = var.location
  resource_group_name      = azurerm_resource_group.rg.name
  tags                     = var.tags
  account_tier             = "Standard"
  account_replication_type = "LRS"
  access_tier              = "Hot"
  min_tls_version          = "TLS1_2"
  spoke_vnet_id            = module.spoke_networking.spoke_vnet_id
  hub_vnet_id              = module.hub_networking.hub_vnet_id
  storage_subnet_id        = module.spoke_networking.storage_subnet_id
}

# ── 6. SQL: primary+reporting servers, DR secondary (centralus), failover group
module "sql_database" {
  source = "./modules/sql_database"

  project_name           = var.project_name
  location               = var.location
  resource_group_name    = azurerm_resource_group.rg.name
  tags                   = var.tags
  sql_admin_username     = var.sql_admin_username
  sql_admin_password     = var.sql_admin_password
  database_sku_primary   = var.database_sku_primary
  database_sku_reporting = var.database_sku_reporting
  secondary_location     = var.secondary_location
  spoke_vnet_id          = module.spoke_networking.spoke_vnet_id
  hub_vnet_id            = module.hub_networking.hub_vnet_id
  data_subnet_id         = module.spoke_networking.data_subnet_id
  alert_email            = var.alert_email
}

# ── 7. Monitoring: CPU/Memory/Disk/SQL-storage alerts + DCR + diagnostics
module "monitoring" {
  source = "./modules/monitoring"

  project_name               = var.project_name
  location                   = var.location
  resource_group_name        = azurerm_resource_group.rg.name
  tags                       = var.tags
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  alert_email                = var.alert_email
  storage_account_id         = module.storage_account.id
  vm_ids                     = { for i, k in local.vm_keys : k => module.windows_vm[i].vm_id }
  sql_db_ids                 = module.sql_database.sql_db_ids
}

# ── 8. Recovery Services Vault: VM daily backups + 12w/12m retention
module "recovery_vault" {
  source = "./modules/recovery_vault"

  project_name        = var.project_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
  vault_redundancy    = var.vault_redundancy
  vm_ids              = { for i, k in local.vm_keys : k => module.windows_vm[i].vm_id }
}

# ── 9. Front Door Premium: global DDoS + CDN — origin = App Gateway public IP
module "front_door" {
  source = "./modules/front_door"

  project_name        = var.project_name
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
  origin_host_name    = module.app_gateway.public_ip
}

# ── 10. NSG Flow Logs — Traffic Analytics for the app subnet NSG ─────────────

resource "azurerm_storage_account" "flow_logs" {
  name                     = "${replace(lower(var.project_name), "/[^a-z0-9]/", "")}flow"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  tags                     = var.tags
}

resource "azurerm_network_watcher" "nw" {
  name                = "${var.project_name}-nw"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

resource "azurerm_network_watcher_flow_log" "app_nsg" {
  network_watcher_name = azurerm_network_watcher.nw.name
  resource_group_name  = azurerm_resource_group.rg.name
  name                 = "${var.project_name}-app-nsg-flowlog"

  network_security_group_id = module.spoke_networking.app_nsg_id
  storage_account_id        = azurerm_storage_account.flow_logs.id
  enabled                   = true

  retention_policy {
    enabled = true
    days    = 90
  }

  traffic_analytics {
    enabled               = true
    workspace_id          = azurerm_log_analytics_workspace.law.workspace_id
    workspace_region      = var.location
    workspace_resource_id = azurerm_log_analytics_workspace.law.id
    interval_in_minutes   = 10
  }

  tags = var.tags
}