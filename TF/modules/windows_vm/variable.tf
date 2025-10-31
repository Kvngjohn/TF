variable "vm_name" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "vm_size" { type = string }

variable "admin_username" {
  description = "The admin username for the Windows VM"
  type        = string
}

variable "admin_password" {
  description = "The admin password for the Windows VM"
  type        = string
  sensitive   = true # This ensures the password is marked as sensitive and won't be printed in logs
}

variable "tags" { type = map(string) }
variable "nic_id" { type = string }
