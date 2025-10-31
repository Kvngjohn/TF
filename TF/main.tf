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

# -------- Root Outputs --------
output "resource_group" { value = module.networking.rg_name }
output "public_ip" { value = module.networking.public_ip }
output "vm_name" { value = local.vm_name }
output "rdp_hint" { value = "mstsc /v:${module.networking.public_ip}:3389" }
output "storage_account_name" { value = module.storage_account.name }
output "storage_account_id" { value = module.storage_account.id }
