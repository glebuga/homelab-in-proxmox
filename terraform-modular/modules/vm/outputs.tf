output "vm_ids" {
  description = "Map of VM IDs keyed by vm_id"
  value       = { for k, vm in proxmox_virtual_environment_vm.this : k => vm.vm_id }
}

output "ipv4_addresses" {
  description = "Map of primary IPv4 addresses keyed by vm_id"

  value = {
    for k, vm in proxmox_virtual_environment_vm.this : k => (
      length(vm.ipv4_addresses) > 0
        ? vm.ipv4_addresses
        : [[split("/", var.vms[k].ip_address)[0]]]
    )
  }
}

output "vms" {
  description = "Full VM resource map keyed by vm_id"
  value       = proxmox_virtual_environment_vm.this
}
