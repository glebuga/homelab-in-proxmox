output "nginx_ip" {
  description = "IP-адрес Nginx сервера"
  value       = proxmox_virtual_environment_container.nginx_bpg.ipv4["eth0"]
}

output "docker_ip" {
  description = "IP-адрес Docker хоста"
  value       = proxmox_virtual_environment_container.docker_bpg.ipv4["eth0"]
}
