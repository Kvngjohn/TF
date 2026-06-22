output "spoke_vnet_id"     { value = azurerm_virtual_network.spoke.id }
output "spoke_vnet_name"   { value = azurerm_virtual_network.spoke.name }
output "app_subnet_id"     { value = azurerm_subnet.app.id }
output "data_subnet_id"    { value = azurerm_subnet.data.id }
output "storage_subnet_id" { value = azurerm_subnet.storage.id }
output "appgw_subnet_id"   { value = azurerm_subnet.appgw.id }
output "app_nsg_id"        { value = azurerm_network_security_group.app_nsg.id }
