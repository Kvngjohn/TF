# ── Project ──────────────────────────────────────────────────────────────────
project_name = "rim-dev"
location     = "eastus2"

# ── Tags ──────────────────────────────────────────────────────────────────────
tags = {
  environment = "dev"
  owner       = "iac"
}

# ── Networking — Hub ──────────────────────────────────────────────────────────
hub_address_space      = "10.0.0.0/16"
firewall_subnet_prefix = "10.0.0.0/26"   # AzureFirewallSubnet (min /26)
hub_mgmt_subnet_prefix = "10.0.1.0/24"
bastion_subnet_prefix  = "10.0.2.0/26"   # AzureBastionSubnet (min /26)

# ── Networking — Spoke ────────────────────────────────────────────────────────
spoke_address_space   = "10.1.0.0/16"
app_subnet_prefix     = "10.1.1.0/24"    # Windows VMs (no public IPs — use Bastion)
data_subnet_prefix    = "10.1.2.0/24"    # SQL private endpoints
storage_subnet_prefix = "10.1.3.0/24"    # Storage Account private endpoint
appgw_subnet_prefix   = "10.1.4.0/24"    # Application Gateway WAF_v2

allow_rdp_from_cidr = "172.172.176.90/32"   # kept for NSG allow-rule in app subnet

# ── Virtual Machines ─────────────────────────────────────────────────────────
vm_size        = "Standard_B2ms"
admin_username = "azureadmin"
# VMs have no public IPs — connect via Azure Bastion in the hub VNet.

# vm_name_1 = "rim-dev-winvm01"   # Uncomment to override default names
# vm_name_2 = "rim-dev-winvm02"
# vm_name_3 = "rim-dev-winvm03"

# ── SQL Databases (DTU-based: S0/S1) ─────────────────────────────────────────
# DTU = bundled CPU+IO+memory. Switch sku to e.g. GP_Gen5_2 for vCore.
# Failover group: primary (eastus2) ↔ DR secondary (centralus), auto, 60-min grace.
# NOTE: sql_admin_username moved to dev.secrets.tfvars — do NOT store credentials here.
database_sku_primary   = "S1"
database_sku_reporting = "S0"
secondary_location     = "centralus"

# ── Recovery Services Vault ───────────────────────────────────────────────────
vault_redundancy = "LocallyRedundant"   # Change to GeoRedundant for DR prod

# ── Monitoring ────────────────────────────────────────────────────────────────
alert_email = "agopeoluwajohn@gmail.com"    # Replace with your real alert recipient

