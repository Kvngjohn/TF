variable "project_name" {
  description = "Project prefix"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "address_space" {
  description = "VNet CIDR (single)"
  type        = string
}

variable "subnet_prefix" {
  description = "Subnet CIDR (single)"
  type        = string
}

variable "allow_rdp_from_cidr" {
  description = "Your public IP /32"
  type        = string
}

variable "vm_size" {
  description = "VM size"
  type        = string
}

variable "admin_username" {
  description = "VM local admin username"
  type        = string
}

variable "admin_password" {
  description = "VM local admin password (set via TF_VAR_admin_password)"
  type        = string
  sensitive   = true
}

variable "vm_name" {
  description = "Optional explicit VM name"
  type        = string
  default     = null
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default = {
    environment = "dev"
  }
}

# Also ensure these are defined for the SQL module
variable "sql_admin_username" {
  type = string
}
variable "sql_admin_password" {
  description = "SQL Server admin password"
  type      = string
  sensitive = true # Recommended
  }
variable "database_sku" {
  description = "Azure SQL Database SKU (e.g., S0, GP_Gen5_2)"
  type        = string
  default     = "S0" # optional; remove if you want tfvars to be mandatory
}