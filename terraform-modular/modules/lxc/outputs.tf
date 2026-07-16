output "ipv4" {
  description = "Primary IPv4 address of the container (eth0)"
  value = split("/", var.ip_address)[0]
}

output "vm_id" {
  description = "Proxmox VM ID of the container"
  value       = proxmox_virtual_environment_container.this.vm_id
}

output "id" {
  description = "Terraform resource ID of the container"
  value       = proxmox_virtual_environment_container.this.id
}
