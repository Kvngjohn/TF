variable "project_name"        { type = string }
variable "location"            { type = string }
variable "resource_group_name" { type = string }
variable "tags"                { type = map(string) }
variable "appgw_subnet_id"     { type = string }

variable "vm_backend_ips" {
  description = "List of VM private IP addresses to include in the backend pool"
  type        = list(string)
}
