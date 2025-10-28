variable "project_name" {
  description = "Short, DNS-safe name used as a prefix for resources"
  type        = string
}

variable "location" {
  description = "Azure region (e.g., eastus2, westeurope)"
  type        = string
  default     = "eastus2"
}

variable "address_space" {
  description = "VNet CIDR"
  type        = string
  default     = "10.20.0.0/16"
}

variable "subnet_prefix" {
  description = "Subnet CIDR"
  type        = string
  default     = "10.20.1.0/24"
}

variable "allow_rdp_from_cidr" {
  description = "Your public IP/CIDR allowed to RDP (e.g., x.x.x.x/32). DO NOT leave 0.0.0.0/0."
  type        = string
  default     = "0.0.0.0/0"
}

variable "vm_size" {
  description = "VM size"
  type        = string
  default     = "Standard_B2ms"
}

variable "admin_username" {
  description = "Local admin username"
  type        = string
  default     = "azureadmin"
}

variable "admin_password" {
  description = "Local admin password"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default = {
    environment = "dev"
    owner       = "iac"
  }
}

variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "tenant_id" {
  description = "Azure Tenant ID"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}
variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}