# -------- Root Outputs --------

# Existing Outputs
output "resource_group" { 
    value = module.networking.rg_name 
}
output "public_ip" { 
    value = module.networking.public_ip 
}
output "vm_name" { 
    value = local.vm_name 
}
output "rdp_hint" { 
    value = "mstsc /v:${module.networking.public_ip}:3389" 
}
output "storage_account_name" { 
    value = module.storage_account.name 
}
output "storage_account_id" { 
    value = module.storage_account.id 
}

# New SQL Database Outputs
output "sql_server_name" {
  description = "The name of the Azure SQL Logical Server"
  value       = module.sql_database.sql_server_name
}

output "sql_database_name" {
  description = "The name of the database created"
  value       = module.sql_database.sql_database_name
}

output "sql_server_fqdn" {
  description = "The Fully Qualified Domain Name (FQDN) used for connecting to the SQL server"
  value       = module.sql_database.sql_server_fqdn
}

output "sql_connection_string_hint" {
    description = "Hint for a standard connection string (you will need to fill in credentials)"
    value = "Server=tcp:${module.sql_database.sql_server_fqdn},1433;Initial Catalog=${module.sql_database.sql_database_name};Persist Security Info=False;User ID={your_username};Password={your_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
}