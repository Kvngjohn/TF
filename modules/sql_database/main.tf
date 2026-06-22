########################################
# SQL servers:
#   primary   (eastus2) — app workload, in auto-failover group
#   dr        (centralus) — failover partner, auto-replicated by Azure
#   reporting (eastus2) — read-heavy standalone, excluded from failover group
#
# Failover group: primary ↔ dr (automatic, 60-min grace period)
# Reporting can be pointed at the FOG read-only listener if desired.
# All servers: public_network_access disabled, private endpoints only.
########################################

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
  lower   = true
  numeric = true
}

locals {
  # Only primary and reporting get TF-managed databases.
  # The DR secondary database is auto-created by Azure when it joins the failover group.
  app_servers = {
    primary   = { sku = var.database_sku_primary }
    reporting = { sku = var.database_sku_reporting }
  }
}

# ── Primary and Reporting servers (primary region) ────────────────────────────

resource "azurerm_mssql_server" "app_servers" {
  for_each = local.app_servers

  name                          = "${var.project_name}-sql-${each.key}-${random_string.suffix.result}"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  version                       = "12.0"
  administrator_login           = var.sql_admin_username
  administrator_login_password  = var.sql_admin_password
  minimum_tls_version           = "1.2"
  public_network_access_enabled = false

  tags = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

# ── DR secondary server (centralus) ──────────────────────────────────────────

resource "azurerm_mssql_server" "dr_secondary" {
  name                          = "${var.project_name}-sql-dr-${random_string.suffix.result}"
  resource_group_name           = var.resource_group_name
  location                      = var.secondary_location
  version                       = "12.0"
  administrator_login           = var.sql_admin_username
  administrator_login_password  = var.sql_admin_password
  minimum_tls_version           = "1.2"
  public_network_access_enabled = false

  tags = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

# ── SQL Auditing — log to Log Analytics ───────────────────────────────────────

resource "azurerm_mssql_server_extended_auditing_policy" "audit" {
  for_each = local.app_servers

  server_id                               = azurerm_mssql_server.app_servers[each.key].id
  log_monitoring_enabled                  = true
  storage_endpoint                        = null
  retention_in_days                       = 0 # logs routed via diagnostic settings
}

resource "azurerm_mssql_server_extended_auditing_policy" "audit_dr" {
  server_id                               = azurerm_mssql_server.dr_secondary.id
  log_monitoring_enabled                  = true
  storage_endpoint                        = null
  retention_in_days                       = 0
}

# ── Advanced Threat Protection ────────────────────────────────────────────────

resource "azurerm_mssql_server_security_alert_policy" "threat" {
  for_each = local.app_servers

  server_name         = azurerm_mssql_server.app_servers[each.key].name
  resource_group_name = var.resource_group_name
  state               = "Enabled"
  email_addresses     = [var.alert_email]
}

resource "azurerm_mssql_server_security_alert_policy" "threat_dr" {
  server_name         = azurerm_mssql_server.dr_secondary.name
  resource_group_name = var.resource_group_name
  state               = "Enabled"
  email_addresses     = [var.alert_email]
}

# ── Databases: primary and reporting only ─────────────────────────────────────

resource "azurerm_mssql_database" "sql_dbs" {
  for_each = local.app_servers

  name      = "${var.project_name}-sqldb-${each.key}"
  server_id = azurerm_mssql_server.app_servers[each.key].id
  collation = "SQL_Latin1_General_CP1_CI_AS"
  sku_name  = each.value.sku

  short_term_retention_policy {
    retention_days           = 35
    backup_interval_in_hours = 12
  }

  long_term_retention_policy {
    weekly_retention  = "P12W"
    monthly_retention = "P12M"
    yearly_retention  = "PT0S"  # set to e.g. "P5Y" for archive compliance
    week_of_year      = 1
  }
}

########################################
# Auto-Failover Group
# Listener FQDN (after apply):
#   <project>-fog.database.windows.net  → always resolves to current primary
#   <project>-fog.secondary.database.windows.net → always the DR replica
########################################

resource "azurerm_mssql_failover_group" "fg" {
  name      = "${var.project_name}-fog"
  server_id = azurerm_mssql_server.app_servers["primary"].id
  databases = [azurerm_mssql_database.sql_dbs["primary"].id]

  partner_server {
    id = azurerm_mssql_server.dr_secondary.id
  }

  read_write_endpoint_failover_policy {
    mode          = "Automatic"
    grace_minutes = 60   # trigger auto-failover after 60 min of primary unavailability
  }

  # Route read-only connections to the secondary replica
  readonly_endpoint_failover_policy_enabled = true

  tags = var.tags
}

########################################
# Private DNS Zone
########################################

resource "azurerm_private_dns_zone" "sql" {
  name                = "privatelink.database.windows.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql_spoke" {
  name                  = "${var.project_name}-sql-dns-spoke"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.sql.name
  virtual_network_id    = var.spoke_vnet_id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql_hub" {
  name                  = "${var.project_name}-sql-dns-hub"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.sql.name
  virtual_network_id    = var.hub_vnet_id
  registration_enabled  = false
  tags                  = var.tags
}

########################################
# Private Endpoints
# DR secondary PE is placed in the primary-region spoke subnet.
# Cross-region private endpoints are valid in Azure and keep
# failover traffic off the public internet.
########################################

resource "azurerm_private_endpoint" "app_server_pe" {
  for_each = local.app_servers

  name                = "${var.project_name}-sql-${each.key}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.data_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.project_name}-sql-${each.key}-psc"
    private_connection_resource_id = azurerm_mssql_server.app_servers[each.key].id
    is_manual_connection           = false
    subresource_names              = ["sqlServer"]
  }

  private_dns_zone_group {
    name                 = "sql-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.sql.id]
  }
}

resource "azurerm_private_endpoint" "dr_secondary_pe" {
  name                = "${var.project_name}-sql-dr-pe"
  location            = var.location   # PE in primary spoke, pointing cross-region to DR server
  resource_group_name = var.resource_group_name
  subnet_id           = var.data_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.project_name}-sql-dr-psc"
    private_connection_resource_id = azurerm_mssql_server.dr_secondary.id
    is_manual_connection           = false
    subresource_names              = ["sqlServer"]
  }

  private_dns_zone_group {
    name                 = "sql-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.sql.id]
  }
}