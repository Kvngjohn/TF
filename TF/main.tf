########################################
# ROOT main.tf  (calls two modules)
########################################

module "networking" {
  source = "./modules/networking"
}

module "windows_vm" {
  source = "./modules/windows_vm"
 
}

