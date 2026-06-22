variable "project_name"        { type = string }
variable "resource_group_name" { type = string }
variable "tags"                { type = map(string) }

variable "origin_host_name" {
  description = "FQDN or IP of the backend origin (e.g. VM public IP or Load Balancer FQDN)"
  type        = string
}
