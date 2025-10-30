variable "rg_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The location of the resources"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
}

variable "vnet_name" {
  description = "The name of the virtual network"
  type        = string
}

variable "address_space" {
  description = "The address space of the virtual network"
  type        = list(string)
}

variable "snet_name" {
  description = "The name of the subnet"
  type        = string
}

variable "subnet_prefix" {
  description = "The address prefix for the subnet"
  type        = list(string)
}

variable "nsg_name" {
  description = "The name of the network security group"
  type        = string
}

variable "allow_rdp_from_cidr" {
  description = "The CIDR range for allowing RDP access"
  type        = string
}

variable "pip_name" {
  description = "The name of the public IP"
  type        = string
}

variable "nic_name" {
  description = "The name of the network interface"
  type        = string
}
