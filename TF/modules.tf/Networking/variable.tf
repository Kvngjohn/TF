variable "rg_name"             { type = string }
variable "location"            { type = string }
variable "tags"                { type = map(string) }

variable "vnet_name"           { type = string }
variable "address_space"       { type = list(string) }

variable "snet_name"           { type = string }
variable "subnet_prefix"       { type = list(string) }

variable "nsg_name"            { type = string }
variable "allow_rdp_from_cidr" { type = string }

variable "pip_name"            { type = string }
variable "nic_name"            { type = string }
