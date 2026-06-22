variable "project_name"               { type = string }
variable "location"                   { type = string }
variable "resource_group_name"        { type = string }
variable "tags"                       { type = map(string) }
variable "log_analytics_workspace_id" { type = string }

variable "alert_email" {
  description = "Email address for alert notifications"
  type        = string
}

variable "vm_ids" {
  description = "Map of VM key -> VM resource ID for CPU/memory alerting and DCR association"
  type        = map(string)
  default     = {}
}

variable "storage_account_id" {
  description = "Resource ID of the storage account (for blob audit diagnostics)"
  type        = string
}

variable "sql_db_ids" {
  description = "Map of DB role -> SQL database resource ID for storage alerts and diagnostics"
  type        = map(string)
  default     = {}
}
