output "vm_name" {
  value = azurerm_windows_virtual_machine.vm.name
}

output "public_ip" {
  value       = azurerm_public_ip.pip.ip_address
  description = "Use this IP for RDP (user/pass from variables)"
}

output "rg_name" {
  value = azurerm_resource_group.rg.name
}