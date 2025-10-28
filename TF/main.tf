module "networking" {
  source              = "./modules/networking"
  rg_name            = "${var.project_name}-rg"
  location           = var.location
  tags               = var.tags
  vnet_name          = "${var.project_name}-vnet"
  address_space      = [var.address_space]
  snet_name          = "${var.project_name}-snet"
  subnet_prefix      = [var.subnet_prefix]
  nsg_name           = "${var.project_name}-nsg"
  allow_rdp_from_cidr = var.allow_rdp_from_cidr
  pip_name           = "${var.project_name}-pip"
  nic_name           = "${var.project_name}-nic"
}

module "windows_vm" {
  source              = "./modules/windows_vm"
  vm_name            = "${var.project_name}-winvm01"
  location           = var.location
  resource_group_name = module.networking.rg_name
  vm_size            = var.vm_size
  admin_username     = var.admin_username
  admin_password     = var.admin_password
  tags               = var.tags
  nic_id             = module.networking.nic_id
}
