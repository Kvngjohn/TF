########################################
# outputs.tf — Outputs for the Windows VM POC
########################################

output "rg_name" {
  value       = azurerm_resource_group.rg.name
  description = "Name of the resource group"
}

output "vm_name" {
  value       = azurerm_windows_virtual_machine.vm.name
  description = "Name of the Windows VM"
}

output "public_ip_address" {
  value       = azurerm_public_ip.pip.ip_address
  description = "Public IP of the Windows VM"
}

output "rdp_command" {
  value       = "mstsc /v:${azurerm_public_ip.pip.ip_address}:3389"
  description = "RDP command to connect to the VM"
}
