variable "project_name" {}
variable "location" {}
variable "resource_group_name" {}
variable "tags" {}

variable "sql_admin_username" {}
variable "sql_admin_password" {}
variable "database_sku" {
  default = "Standard_S0"
}
variable "allow_my_ip" {
  default = false
}
variable "my_public_ip" {
  default = "0.0.0.0" # Placeholder, update this in root module
}
