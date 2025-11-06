########################################
# ROOT main.tf (calls modules)
########################################

locals {
  vm_name = coalesce(var.vm_name, "${var.project_name}-winvm01")
}

module "networking" {
  source = "./modules/networking"

  rg_name  = "${var.project_name}-rg"
  location = var.location
  tags     = var.tags

  vnet_name     = "${var.project_name}-vnet"
  address_space = [var.address_space] # module expects list

  snet_name     = "${var.project_name}-snet"
  subnet_prefix = [var.subnet_prefix] # module expects list

  nsg_name            = "${var.project_name}-nsg"
  allow_rdp_from_cidr = var.allow_rdp_from_cidr

  pip_name = "${var.project_name}-pip"
  nic_name = "${var.project_name}-nic"
}

module "windows_vm" {
  source = "./modules/windows_vm"

  vm_name             = local.vm_name
  location            = var.location
  resource_group_name = module.networking.rg_name
  vm_size             = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  tags                = var.tags
  nic_id              = module.networking.nic_id
}

module "storage_account" {
  source = "./modules/storage_account"

  project_name        = var.project_name
  location            = var.location
  resource_group_name = module.networking.rg_name
  tags                = var.tags

  # Optional: change if you like
  account_tier             = "Standard"
  account_replication_type = "LRS"
  access_tier              = "Hot"
  min_tls_version          = "TLS1_2"
}
module "sql_database" {
  source = "./modules/sql_database"

  project_name        = var.project_name
  location            = var.location
  resource_group_name = module.networking.rg_name # Reusing the RG created by networking module
  tags                = var.tags

  sql_admin_username = var.sql_admin_username
  sql_admin_password = var.sql_admin_password # Reusing the VM admin password for simplicity
  database_sku       = "Standard_S0"
  
  # Set to true and provide your IP to allow access from where you run terraform
  allow_my_ip  = true 
}