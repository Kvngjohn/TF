project_name        = "winvm-poc"
location            = "eastus2"
address_space       = "10.20.0.0/16"
subnet_prefix       = "10.20.1.0/24"
allow_rdp_from_cidr = "x.x.x.x/32" # <-- YOUR public IP; do NOT leave 0.0.0.0/0
vm_size             = "Standard_B2ms"
admin_username      = "azureadmin"
# admin_password   comes from TF_VAR_admin_password in CI (don’t put it here)
tags = {
  environment = "dev"
  owner       = "john"

}
