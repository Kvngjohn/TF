output "public_ip" {
  description = "App Gateway public IP — set as Front Door origin_host_name"
  value       = azurerm_public_ip.appgw_pip.ip_address
}

output "appgw_id" {
  value = azurerm_application_gateway.appgw.id
}
