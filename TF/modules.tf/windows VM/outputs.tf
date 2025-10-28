output "vm_id" {
  description = "ID of the virtual machine"
  value       = module.windows_vm.vm_id
}
output "vm_ip_address" {
  description = "Public IP address of the virtual machine"
  value       = module.windows_vm.public_ip_address
}