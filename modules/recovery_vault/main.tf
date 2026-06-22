########################################
# Recovery Services Vault
# VM backup: daily (30d) → weekly (12w) → monthly (12m)
# SQL short-term and long-term retention is configured in the
# sql_database module directly on the azurerm_mssql_database resource.
########################################

resource "azurerm_recovery_services_vault" "rsv" {
  name                = "${var.project_name}-rsv"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  storage_mode_type   = var.vault_redundancy  # "GeoRedundant" for prod DR, "LocallyRedundant" for dev
  soft_delete_enabled = true
  tags                = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_backup_policy_vm" "daily" {
  name                = "${var.project_name}-vm-backup-policy"
  resource_group_name = var.resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.rsv.name
  timezone            = "UTC"

  # V2 = Enhanced policy: supports sub-daily (hourly) backup frequency
  policy_type = "V2"

  backup {
    frequency     = "Hourly"
    time          = "00:00"     # start of the backup window
    hour_interval = 8           # snapshot every 8 hours (valid: 4, 6, 8, 12)
    hour_duration = 24          # backup window covers the full day
  }

  retention_daily {
    count = 120   # 120 days of daily restore points
  }

  retention_weekly {
    count    = 12
    weekdays = ["Sunday"]
  }

  retention_monthly {
    count    = 12
    weekdays = ["Sunday"]
    weeks    = ["First"]
  }
}

# Enroll each VM in the daily backup policy
resource "azurerm_backup_protected_vm" "vms" {
  for_each = var.vm_ids

  resource_group_name = var.resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.rsv.name
  source_vm_id        = each.value
  backup_policy_id    = azurerm_backup_policy_vm.daily.id
}
