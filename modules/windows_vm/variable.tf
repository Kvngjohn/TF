variable "vm_name"             { type = string }
variable "location"            { type = string }
variable "resource_group_name" { type = string }
variable "vm_size"             { type = string }
variable "subnet_id"           { type = string }

variable "create_public_ip" {
  description = "Attach a public IP to this VM. Set false for Bastion-only access."
  type        = bool
  default     = true
}

variable "admin_username" {
  description = "Local admin username for the Windows VM"
  type        = string
}

variable "admin_password" {
  description = "Local admin password for the Windows VM"
  type        = string
  sensitive   = true
}
variable "alert_email" {
  description = "Email address to receive Azure Monitor alert notifications"
  type        = string
}
variable "tags" { type = map(string) }
