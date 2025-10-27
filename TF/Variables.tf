variable "project_name" {
  description = "Short name for this POC"
  type        = string
  default     = "rim-dev"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus2"
}

variable "address_space" {
  description = "VNet CIDR"
  type        = string
  default     = "10.40.0.0/16"
}

variable "subnet_prefix" {
  description = "Subnet CIDR"
  type        = string
  default     = "10.40.1.0/24"
}

variable "admin_username" {
  description = "Windows VM admin username"
  type        = string
  default     = "azureadmin"
}

variable "admin_password" {
  description = "Windows VM admin password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "vm_size" {
  description = "VM size (stay small for free tier credits)"
  type        = string
  default     = "Standard_B2s"
}

variable "allow_rdp_from_cidr" {
  description = "Your public IP/CIDR to allow RDP (3389). Use x.x.x.x/32"
  type        = string
  default     = "0.0.0.0/0" # CHANGE to your IP for security or Use a VPN/Private Endpoint and keep RDP fully private.
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {
    "env"     = "dev"
    "owner"   = "John"
    "project" = "winvm-poc"
  }
}

variable "subscription_id" {
  description = "Optional: Azure subscription id to explicitly use for provider. Not secret."
  type        = string
  default     = ""
}

variable "tenant_id" {
  description = "Optional: Azure tenant id to explicitly use for provider."
  type        = string
  default     = ""
}

variable "use_cli" {
  description = "Whether to use the local Azure CLI session for auth (true for local dev). Set to false in CI when using a service principal."
  type        = bool
  default     = true
}