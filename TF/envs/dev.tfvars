project_name        = "rim-dev"# your public IP /32
vm_size             = "Standard_B2ms"
admin_username = "azureadmin"
admin_password = "Coldstone@2424@"

tags = {
  environment = "dev"
  owner       = "iac"
}
# DO NOT put admin_password here. Set it via TF_VAR_admin_password.

rg_name             = "myResourceGroup"
location           = "East US 2"
vnet_name           = "myVnet"
address_space       = ["10.0.0.0/16"]
snet_name           = "mySubnet"
subnet_prefix      = ["10.0.1.0/24"]
nsg_name            = "myNSG"
allow_rdp_from_cidr = "17.172.176.90/32"
pip_name            = "myPublicIP"
nic_name            = "myNIC"
