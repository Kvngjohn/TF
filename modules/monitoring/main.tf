########################################
# Monitoring — Action Group, VM CPU/Memory/Disk alerts,
# SQL storage % alert, Storage + SQL diagnostic settings.
#
# VM disk space flow:
#   AMA extension (installed by windows_vm module)
#   → Data Collection Rule (DCR) pulls LogicalDisk % Free Space
#   → Log Analytics Workspace (Perf table)
#   → Scheduled Query Alert fires when any disk < 20% free
#
# SQL storage:
#   Native metric storage_percent on each DB → metric alert at 80%
########################################

resource "azurerm_monitor_action_group" "alerts" {
  name                = "${var.project_name}-alert-ag"
  resource_group_name = var.resource_group_name
  short_name          = "alerts"
  tags                = var.tags

  email_receiver {
    name          = "ops-email"
    email_address = var.alert_email
  }
}

# ── VM CPU spike (native host metric — no agent needed) ─────────────────────
resource "azurerm_monitor_metric_alert" "vm_cpu" {
  for_each = var.vm_ids

  name                = "${var.project_name}-cpu-${each.key}"
  resource_group_name = var.resource_group_name
  scopes              = [each.value]
  description         = "CPU > 80% for 15 min on ${each.key}"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"
  tags                = var.tags

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action { action_group_id = azurerm_monitor_action_group.alerts.id }
}

# ── VM Memory alert (requires AMA — installed by windows_vm module) ──────────
resource "azurerm_monitor_metric_alert" "vm_memory" {
  for_each = var.vm_ids

  name                = "${var.project_name}-mem-${each.key}"
  resource_group_name = var.resource_group_name
  scopes              = [each.value]
  description         = "Available memory < 1 GB on ${each.key}"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"
  tags                = var.tags

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Available Memory Bytes"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 1073741824 # 1 GB in bytes
  }

  action { action_group_id = azurerm_monitor_action_group.alerts.id }
}

# ── DCR: collect Windows guest disk + memory perf counters into Log Analytics ─
# Also publishes InsightsMetrics to Azure Monitor for metric alerts.
resource "azurerm_monitor_data_collection_rule" "vm_perf" {
  name                = "${var.project_name}-vm-perf-dcr"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  destinations {
    log_analytics {
      workspace_resource_id = var.log_analytics_workspace_id
      name                  = "law-destination"
    }
    azure_monitor_metrics {
      name = "metrics-destination"
    }
  }

  data_flow {
    streams      = ["Microsoft-Perf"]
    destinations = ["law-destination"]
  }

  data_flow {
    streams      = ["Microsoft-InsightsMetrics"]
    destinations = ["metrics-destination"]
  }

  data_sources {
    performance_counter {
      name                          = "vm-disk-mem-counters"
      sampling_frequency_in_seconds = 60
      streams                       = ["Microsoft-Perf", "Microsoft-InsightsMetrics"]
      counter_specifiers = [
        "\\LogicalDisk(*)\\% Free Space",
        "\\LogicalDisk(*)\\Free Megabytes",
        "\\Memory\\Available Bytes",
        "\\Memory\\% Committed Bytes In Use",
        "\\Processor(_Total)\\% Processor Time",
      ]
    }
  }
}

# Associate DCR with each VM so AMA knows where to ship counters
resource "azurerm_monitor_data_collection_rule_association" "vm_perf" {
  for_each = var.vm_ids

  name                    = "${var.project_name}-dcr-assoc-${each.key}"
  target_resource_id      = each.value
  data_collection_rule_id = azurerm_monitor_data_collection_rule.vm_perf.id
}

# ── VM disk space — Log Query Alert ──────────────────────────────────────────
# Fires when any volume on any enrolled VM drops below 20% free space.
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "vm_disk_low" {
  name                 = "${var.project_name}-vm-disk-low"
  location             = var.location
  resource_group_name  = var.resource_group_name
  description          = "Alert when any VM disk free space < 20% (via DCR Perf table)"
  severity             = 2
  evaluation_frequency = "PT5M"
  window_duration      = "PT15M"
  scopes               = [var.log_analytics_workspace_id]
  tags                 = var.tags

  criteria {
    # Count rows where any volume reports < 20% free; fire if count > 0
    query = <<-KQL
      Perf
      | where ObjectName == "LogicalDisk"
      | where CounterName == "% Free Space"
      | where InstanceName !in ("_Total", "HarddiskVolume1")
      | where CounterValue < 20
      | summarize AggregatedValue = count() by bin(TimeGenerated, 5m)
    KQL

    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.alerts.id]
  }
}

# ── SQL storage % — metric alert per database ────────────────────────────────
# DTU-based metric; also works on vCore (same metric namespace).
resource "azurerm_monitor_metric_alert" "sql_storage" {
  for_each = var.sql_db_ids

  name                = "${var.project_name}-sql-storage-${each.key}"
  resource_group_name = var.resource_group_name
  scopes              = [each.value]
  description         = "SQL ${each.key} database storage > 80% of allocated size"
  severity            = 2
  frequency           = "PT15M"
  window_size         = "PT1H"
  tags                = var.tags

  criteria {
    metric_namespace = "Microsoft.Sql/servers/databases"
    metric_name      = "storage_percent"
    aggregation      = "Maximum"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action { action_group_id = azurerm_monitor_action_group.alerts.id }
}

# ── Storage blob diagnostic settings (audit logs) ────────────────────────────
resource "azurerm_monitor_diagnostic_setting" "storage_blob" {
  name                       = "${var.project_name}-storage-blob-diag"
  target_resource_id         = "${var.storage_account_id}/blobServices/default"
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log { category = "StorageRead" }
  enabled_log { category = "StorageWrite" }
  enabled_log { category = "StorageDelete" }

  metric {
    category = "Transaction"
    enabled  = true
  }
}

# ── SQL database diagnostic settings ─────────────────────────────────────────
resource "azurerm_monitor_diagnostic_setting" "sql_db" {
  for_each = var.sql_db_ids

  name                       = "${var.project_name}-sqldb-${each.key}-diag"
  target_resource_id         = each.value
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log { category = "SQLInsights" }
  enabled_log { category = "QueryStoreRuntimeStatistics" }
  enabled_log { category = "QueryStoreWaitStatistics" }
  enabled_log { category = "Errors" }
  enabled_log { category = "Deadlocks" }

  metric {
    category = "Basic"
    enabled  = true
  }
}
