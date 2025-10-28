variable "vm_name" {
  description = "The name of the virtual machine"
  type        = string
}

variable "location" {
  description = "The location of the virtual machine"
  type        = string
}

variable "resource_group_name" {
  description = "The resource group name"
  type        = string
}

variable "vm_size" {
  description = "The size of the virtual machine"
  type        = string
}

variable "admin_username" {
  description = "The admin username for the VM"
  type        = string
}

variable "admin_password" {
  description = "The admin password for the VM"
  type        = string
}

variable "tags" {
  description = "Tags for the virtual machine"
  type        = map(string)
}

variable "nic_id" {
  description = "The network interface ID for the virtual machine"
  type        = string
}
