output "rg_name" { value = azurerm_resource_group.rg.name }
output "nic_id" { value = azurerm_network_interface.nic.id }
output "public_ip" { value = azurerm_public_ip.pip.ip_address }
