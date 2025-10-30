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
