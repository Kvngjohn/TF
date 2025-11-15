terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Generate random suffix for global uniqueness
resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
  lower   = true
  numeric = true
}

# Azure SQL Server
resource "azurerm_mssql_server" "sql_server" {
  name                         = "${var.project_name}-sql-${random_string.suffix.result}"
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = var.sql_admin_password

  minimum_tls_version          = "1.2"
  public_network_access_enabled = true

  tags = var.tags
}

# Azure SQL Database
resource "azurerm_mssql_database" "sql_db" {
  name      = "${var.project_name}-sqldb"
  server_id = azurerm_mssql_server.sql_server.id
  sku_name  = var.database_sku
  collation = "SQL_Latin1_General_CP1_CI_AS"
}