output "resource_group_name" {
  value = azurerm_resource_group.main.name
}
 
output "vm_public_ips" {
  description = "Public IPs of every VM in the fleet."
  value       = azurerm_public_ip.vm[*].ip_address
}
 
output "admin_username" {
  value = var.admin_username
}
 
output "inventory_path" {
  description = "Where Terraform wrote the Ansible inventory."
  value       = local_file.ansible_inventory.filename
}
 
output "first_vm_ssh_hint" {
  description = "Copy-paste this to SSH into the first VM."
  value       = "ssh -i ${var.ssh_private_key_path} ${var.admin_username}@${azurerm_public_ip.vm[0].ip_address}"
}
