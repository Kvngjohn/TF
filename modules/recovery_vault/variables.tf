variable "project_name"        { type = string }
variable "location"            { type = string }
variable "resource_group_name" { type = string }
variable "tags"                { type = map(string) }

variable "vm_ids" {
  description = "Map of VM key -> VM resource ID (e.g. vm01 -> /subscriptions/...)"
  type        = map(string)
}

variable "vault_redundancy" {
  description = "Storage redundancy for the Recovery Services Vault. Use GeoRedundant for DR, LocallyRedundant for dev."
  type        = string
  default     = "LocallyRedundant"
}
