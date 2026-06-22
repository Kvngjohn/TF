output "vm_id"       { value = azurerm_windows_virtual_machine.vm.id }
output "vm_name"     { value = azurerm_windows_virtual_machine.vm.name }
output "public_ip"   { value = var.create_public_ip ? azurerm_public_ip.pip[0].ip_address : null }
output "private_ip"  { value = azurerm_network_interface.nic.private_ip_address }
