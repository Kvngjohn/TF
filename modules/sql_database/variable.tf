variable "project_name"        { type = string }
variable "location"            { type = string }
variable "resource_group_name" { type = string }
variable "tags"                { type = map(string) }
variable "spoke_vnet_id"       { type = string }
variable "hub_vnet_id"         { type = string }
variable "data_subnet_id"      { type = string }

variable "secondary_location" {
  description = "Azure region for the DR secondary SQL server (failover partner)"
  type        = string
  default     = "centralus"
}

variable "sql_admin_username" {
  description = "SQL Server administrator login"
  type        = string
}

variable "sql_admin_password" {
  description = "SQL Server administrator password"
  type        = string
  sensitive   = true
}

variable "database_sku_primary" {
  description = "SKU for the primary SQL database (DTU: S0-S12; vCore: GP_Gen5_2 etc.)"
  type        = string
  default     = "S1"
}

variable "database_sku_reporting" {
  description = "SKU for the reporting SQL database (read-heavy; lower tier is fine)"
  type        = string
  default     = "S0"
}

variable "alert_email" {
  description = "Email address for SQL threat detection alerts"
  type        = string
}
