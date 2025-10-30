project_name        = "rim-dev"
location            = "eastus2"
address_space       = "10.20.0.0/16"
subnet_prefix       = "10.20.1.0/24"
allow_rdp_from_cidr = "17.172.176.90/32" # your public IP /32
vm_size             = "Standard_B2ms"
admin_username = "azureadmin"
admin_password = "Coldstone@2424@"

tags = {
  environment = "dev"
  owner       = "iac"
}
# DO NOT put admin_password here. Set it via TF_VAR_admin_password.
