# modules/sql_database/main.tf

resource "azurerm_mssql_server" "sql_server" {
  # Server names must be globally unique, 3-64 chars, a-z, 0-9, hyphen. 
  # We use a random string suffix to ensure uniqueness.
  name                         = "${var.project_name}-sqlserver-${random_string.suffix.result}"
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = "12.0" # or "12.0" (Azure SQL DB uses this version identifier)
  administrator_login          = var.sql_admin_username
  administrator_login_password = var.sql_admin_password
  tags                         = var.tags
}

resource "azurerm_mssql_database" "sql_db" {
  name      = "${var.project_name}-sqldb"
  server_id = azurerm_mssql_server.sql_server.id
  sku_name  = var.database_sku # e.g., "Standard_S0", "Basic", "GP_Gen5_1"
}

# Resource to generate a random suffix for global uniqueness
resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
  lower   = true
  numeric  = true
}
