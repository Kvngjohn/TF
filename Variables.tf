########################################
# Root Variables — Hub-Spoke Architecture
########################################

variable "project_name" {
  description = "Project prefix used for all resource names"
  type        = string
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
}

variable "tags" {
  description = "Common tags applied to every resource"
  type        = map(string)
  default = {
    environment = "dev"
    owner       = "iac"
    managed-by  = "terraform"
  }
}

# ── Networking ──────────────────────────────────────────────────────────────

variable "hub_address_space" {
  description = "CIDR for the Hub VNet (must not overlap with spoke)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "firewall_subnet_prefix" {
  description = "CIDR for AzureFirewallSubnet — minimum /26 required by Azure"
  type        = string
  default     = "10.0.0.0/26"
}

variable "hub_mgmt_subnet_prefix" {
  description = "CIDR for the hub management subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "bastion_subnet_prefix" {
  description = "CIDR for AzureBastionSubnet — minimum /26 required by Azure"
  type        = string
  default     = "10.0.2.0/26"
}

variable "spoke_address_space" {
  description = "CIDR for the Spoke VNet"
  type        = string
  default     = "10.1.0.0/16"
}

variable "app_subnet_prefix" {
  description = "CIDR for the app subnet (Windows VMs)"
  type        = string
  default     = "10.1.1.0/24"
}

variable "data_subnet_prefix" {
  description = "CIDR for the data subnet (SQL private endpoints)"
  type        = string
  default     = "10.1.2.0/24"
}

variable "storage_subnet_prefix" {
  description = "CIDR for the storage subnet (Storage Account private endpoint)"
  type        = string
  default     = "10.1.3.0/24"
}

variable "appgw_subnet_prefix" {
  description = "CIDR for the App Gateway subnet — minimum /26, /24 recommended for WAF_v2"
  type        = string
  default     = "10.1.4.0/24"
}

variable "allow_rdp_from_cidr" {
  description = "Trusted source CIDR for RDP access to the app subnet (e.g. your office /32)"
  type        = string
}

# ── Virtual Machines ────────────────────────────────────────────────────────

variable "vm_size" {
  description = "VM SKU for all three Windows servers"
  type        = string
  default     = "Standard_B2ms"
}

# Note: VMs no longer get public IPs — use Azure Bastion (in hub VNet) for RDP access.

variable "vm_name_1" {
  description = "Override name for VM 1 (primary); defaults to <project>-winvm01"
  type        = string
  default     = null
}

variable "vm_name_2" {
  description = "Override name for VM 2 (secondary); defaults to <project>-winvm02"
  type        = string
  default     = null
}

variable "vm_name_3" {
  description = "Override name for VM 3 (reporting); defaults to <project>-winvm03"
  type        = string
  default     = null
}

# ── Recovery Services Vault ─────────────────────────────────────────────────

variable "vault_redundancy" {
  description = "RSV storage redundancy: LocallyRedundant for dev, GeoRedundant for production DR"
  type        = string
  default     = "LocallyRedundant"
}

variable "admin_username" {
  description = "Local admin username for all Windows VMs"
  type        = string
}

variable "admin_password" {
  description = "Local admin password — set via TF_VAR_admin_password or secrets store"
  type        = string
  sensitive   = true
}

# ── SQL Databases ───────────────────────────────────────────────────────────

variable "sql_admin_username" {
  description = "SQL Server administrator login"
  type        = string
}

variable "sql_admin_password" {
  description = "SQL Server administrator password — set via TF_VAR_sql_admin_password"
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

variable "secondary_location" {
  description = "Azure region for the DR secondary SQL server (auto-failover group partner)"
  type        = string
  default     = "centralus"
}

# ── Monitoring ──────────────────────────────────────────────────────────────

variable "alert_email" {
  description = "Email address to receive Azure Monitor alert notifications"
  type        = string
}
