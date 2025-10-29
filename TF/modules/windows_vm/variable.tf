# variables.tf

variable "vm_name" {
  description = "The name of the virtual machine."
  type        = string
}

variable "location" {
  description = "The Azure region where the VM will be deployed."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group where the VM will be deployed."
  type        = string
}

variable "vm_size" {
  description = "The size of the virtual machine."
  type        = string
}

variable "admin_username" {
  description = "The admin username for the virtual machine."
  type        = string
}

variable "admin_password" {
  description = "The admin password for the virtual machine."
  type        = string
  sensitive   = true  # This ensures the password is treated securely
}

variable "tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
}

variable "nic_id" {
  description = "The network interface ID associated with the VM."
  type        = string
}