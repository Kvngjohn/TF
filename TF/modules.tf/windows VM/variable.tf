variable "vm_name"             { type = string }
variable "location"            { type = string }
variable "resource_group_name" { type = string }
variable "vm_size"             { type = string }

variable "admin_username" { type = string }

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "tags"  { type = map(string) }
variable "nic_id"{ type = string }
