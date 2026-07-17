output "nginx_ip" {
  description = "IP-адрес Nginx сервера"
  value       = module.nginx.ipv4
}

output "docker_ip" {
  description = "IP-адрес Docker"
  value       = module.docker.ipv4
}

output "dns_ip" {
  description = "IP-адрес DNS сервера"
  value       = module.net_services.ipv4
}

output "gitlab_ip" {
  description = "IP-адрес GitLab сервера"
  value       = module.gitlab.ipv4
}

output "ubuntu_vm_ips" {
  description = "IPv4 addresses of Ubuntu VMs keyed by vm_id"
  value       = module.ubuntu_vms.ipv4_addresses
}

output "k3s_vm_ips" {
  description = "IPv4 addresses of K3s VMs keyed by vm_id"
  value       = module.k3s_vms.ipv4_addresses
}

# output "vm_ubuntu_ip" {
#   description = "IP-адрес VM Ubuntu"
#   value       = values(module.ubuntu_vms.ipv4_addresses)[0]
# }

output "harbor_ip" {
  description = "IP-адрес Harbor registry"
  value       = module.harbor.ipv4
}
