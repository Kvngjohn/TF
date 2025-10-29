# TF/envs/dev.tfvars - Variables for dev environment

project_name        = "rim-dev"
location            = "eastus2"
address_space       = "10.20.0.0/16"
subnet_prefix       = "10.20.1.0/24"
allow_rdp_from_cidr = "x.x.x.x/32"   # put YOUR public IP /32
vm_size             = "Standard_B2ms"
admin_username      = "azureadmin"

tags = {
  environment = "dev"
  owner       = "john"
}

# Ideally, this would be dynamic or pulled from a data resource.
# If it's static for your environment, keep it as is. Otherwise, try to dynamically find the subnet:
subnet_id = "/subscriptions/{subscription-id}/resourceGroups/{resource-group}/providers/Microsoft.Network/virtualNetworks/{vnet-name}/subnets/{subnet-name}"
