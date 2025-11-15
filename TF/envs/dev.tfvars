# Project settings
project_name = "rim-dev"
location     = "eastus2"
resource_group_name = "rg-rim-dev"

# Networking
address_space = "10.0.0.0/16"
subnet_prefix = "10.0.1.0/24"
allow_rdp_from_cidr = "172.172.176.90/32"

# VM settings
vm_size        = "Standard_B2ms"
admin_username = "azureadmin"

# Tags
tags = {
  environment = "dev"
  owner       = "iac"
}

# SQL settings
sql_admin_username = "Kvngjohn"  # Password comes from GitHub secret
database_sku       = "Standard_S0"