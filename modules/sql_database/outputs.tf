output "sql_server_names" {
  description = "Map of role -> SQL server name (primary, reporting)"
  value       = { for k, v in azurerm_mssql_server.app_servers : k => v.name }
}

output "sql_server_ids" {
  description = "Map of role -> SQL server resource ID"
  value       = { for k, v in azurerm_mssql_server.app_servers : k => v.id }
}

output "sql_server_fqdns" {
  description = "Map of role -> FQDN (resolves via private DNS inside VNet)"
  value       = { for k, v in azurerm_mssql_server.app_servers : k => v.fully_qualified_domain_name }
}

output "sql_db_ids" {
  description = "Map of role -> SQL database resource ID (used by monitoring)"
  value       = { for k, v in azurerm_mssql_database.sql_dbs : k => v.id }
}

output "sql_db_names" {
  description = "Map of role -> SQL database name"
  value       = { for k, v in azurerm_mssql_database.sql_dbs : k => v.name }
}

output "dr_secondary_server_name" {
  description = "DR secondary SQL server name (centralus)"
  value       = azurerm_mssql_server.dr_secondary.name
}

output "failover_group_name" {
  description = "Auto-failover group name"
  value       = azurerm_mssql_failover_group.fg.name
}

output "failover_group_rw_endpoint" {
  description = "Read-write listener FQDN — always resolves to current primary. Use this in app connection strings."
  value       = "${azurerm_mssql_failover_group.fg.name}.database.windows.net"
}

output "failover_group_ro_endpoint" {
  description = "Read-only listener FQDN — always resolves to current secondary (DR replica)."
  value       = "${azurerm_mssql_failover_group.fg.name}.secondary.database.windows.net"
}