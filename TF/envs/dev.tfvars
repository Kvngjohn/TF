project_name = "rim-dev"
location     = "eastus2"

# root expects strings (the module converts them to lists)
address_space = "10.0.0.0/16"
subnet_prefix = "10.0.1.0/24"

allow_rdp_from_cidr = "172.172.176.90/32"

vm_size        = "Standard_B2ms"
admin_username = "azureadmin"

tags = {
  environment = "dev"
  owner       = "iac"
}

# DO NOT add any of these here:
# rg_name, vnet_name, snet_name, nsg_name, pip_name, nic_name, vm_name, admin_password
