output "nginx_ip" {
  description = "IP-адрес Nginx сервера"
  value       = proxmox_virtual_environment_container.nginx_bpg.ipv4["eth0"]
}

output "docker_ip" {
  description = "IP-адрес Docker"
  value       = proxmox_virtual_environment_container.docker_bpg.ipv4["eth0"]
}

output "dns_ip" {
  description = "IP-адрес DNS сервера"
  value       = proxmox_virtual_environment_container.net_services_bpg.ipv4["eth0"]
}

# output "vm_ubuntu_ip" {
#   description = "IP-адрес VM Ubuntu"
#   value       = proxmox_virtual_environment_vm.ubuntu_vm.ipv4_addresses[1][0]
# }