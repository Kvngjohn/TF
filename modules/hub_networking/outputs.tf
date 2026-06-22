output "hub_vnet_id"         { value = azurerm_virtual_network.hub.id }
output "hub_vnet_name"       { value = azurerm_virtual_network.hub.name }
output "firewall_id"         { value = azurerm_firewall.firewall.id }
output "firewall_private_ip" { value = azurerm_firewall.firewall.ip_configuration[0].private_ip_address }
output "firewall_public_ip"  { value = azurerm_public_ip.firewall_pip.ip_address }
output "spoke_udr_id"        { value = azurerm_route_table.spoke_udr.id }
output "bastion_id"          { value = azurerm_bastion_host.bastion.id }
output "bastion_dns_name"    { value = azurerm_bastion_host.bastion.dns_name }
