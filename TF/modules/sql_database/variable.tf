# Variables
variable "project_name" {
  description = "Project name prefix for resources"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "tags" {
  description = "Tags for resources"
  type        = map(string)
}

variable "sql_admin_username" {
  description = "SQL Server admin username"
  type        = string
}

variable "sql_admin_password" {
  description = "SQL Server admin password"
  type        = string
  sensitive   = true
  }
variable "database_sku" {
  description = "Azure SQL Database SKU (e.g., S0, GP_Gen5_2)"
  type        = string
  default     = "S0" # or remove default to force tfvars input
}
