########################################
# Root Outputs — Hub-Spoke Architecture
########################################

output "resource_group" {
  value = azurerm_resource_group.rg.name
}

# ── Networking ──────────────────────────────────────────────────────────────

output "hub_vnet_id" {
  value = module.hub_networking.hub_vnet_id
}

output "spoke_vnet_id" {
  value = module.spoke_networking.spoke_vnet_id
}

output "firewall_public_ip" {
  description = "Azure Firewall egress IP — whitelist this for any outbound allowlists"
  value       = module.hub_networking.firewall_public_ip
}

output "firewall_private_ip" {
  value = module.hub_networking.firewall_private_ip
}

# ── Bastion ─────────────────────────────────────────────────────────────────

output "bastion_dns_name" {
  description = "Open Azure Portal → Bastion → Connect; or use az network bastion rdp --name ..."
  value       = module.hub_networking.bastion_dns_name
}

# ── Virtual Machines ────────────────────────────────────────────────────────

output "vm_names" {
  value = [for vm in module.windows_vm : vm.vm_name]
}

output "vm_private_ips" {
  description = "Private IPs — connect via Bastion (no public IPs)"
  value       = [for vm in module.windows_vm : vm.private_ip]
}

# ── Application Gateway ──────────────────────────────────────────────────────

output "app_gateway_public_ip" {
  description = "App Gateway frontend IP — Front Door routes here; also reachable directly for testing"
  value       = module.app_gateway.public_ip
}

# ── Storage ─────────────────────────────────────────────────────────────────

output "storage_account_name" {
  value = module.storage_account.name
}

# ── SQL Databases ────────────────────────────────────────────────────────────

output "sql_server_names" {
  description = "Map of role -> SQL server name (primary, reporting)"
  value       = module.sql_database.sql_server_names
}

output "sql_server_fqdns" {
  description = "Individual server FQDNs (resolves via private DNS inside VNet)"
  value       = module.sql_database.sql_server_fqdns
}

output "sql_db_names" {
  description = "Map of role -> SQL database name"
  value       = module.sql_database.sql_db_names
}

output "failover_group_rw_endpoint" {
  description = "Use this FQDN in app connection strings — always points to current primary"
  value       = module.sql_database.failover_group_rw_endpoint
}

output "failover_group_ro_endpoint" {
  description = "Read-only listener — always points to current DR secondary"
  value       = module.sql_database.failover_group_ro_endpoint
}

output "dr_secondary_server_name" {
  description = "DR secondary SQL server name (centralus)"
  value       = module.sql_database.dr_secondary_server_name
}

# ── Backups ──────────────────────────────────────────────────────────────────

output "recovery_vault_name" {
  description = "Recovery Services Vault — VMs enrolled with daily/weekly/monthly policy"
  value       = module.recovery_vault.vault_name
}

# ── Monitoring ───────────────────────────────────────────────────────────────

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.law.id
}

# ── Front Door ───────────────────────────────────────────────────────────────

output "front_door_endpoint_hostname" {
  description = "CNAME your public domain to this hostname to route through Front Door"
  value       = module.front_door.front_door_endpoint_hostname
}

