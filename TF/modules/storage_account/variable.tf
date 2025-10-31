variable "project_name"        { type = string }
variable "location"            { type = string }
variable "resource_group_name" { type = string }
variable "tags"                { type = map(string) }

variable "account_tier"             { type = string }           # "Standard" | "Premium"
variable "account_replication_type" { type = string }           # "LRS" | "ZRS" | "GRS" | "GZRS" | "RAGRS"
variable "access_tier"              { type = string }           # "Hot" | "Cool"
variable "min_tls_version"          { type = string }           # "TLS1_2" | "TLS1_3"
