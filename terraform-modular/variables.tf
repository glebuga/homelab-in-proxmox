# ---------------------------------------------------------------------------
# Proxmox provider & shared infrastructure
# ---------------------------------------------------------------------------

variable "pm_api_url" {
  description = "URL для API Proxmox"
  type        = string
  default     = "https://192.168.0.200:8006/"
}

variable "pm_api_token" {
  description = "Proxmox API token (id=secret format)"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Target Proxmox node name"
  type        = string
}

variable "template_id" {
  description = "LXC template ID for container clones"
  type        = number
}

variable "dns_server" {
  description = "Default DNS server for LXC containers and Ubuntu VMs"
  type        = string
}

variable "router_dns_server" {
  description = "DNS server used by K3s VMs (typically upstream router DNS)"
  type        = string
}

variable "search_domain" {
  description = "DNS search domain for all resources"
  type        = string
}

variable "gateway" {
  description = "Default network gateway"
  type        = string
}

# ---------------------------------------------------------------------------
# LXC container definitions
# ---------------------------------------------------------------------------

variable "docker_container" {
  description = "Docker LXC container configuration"
  type = object({
    vm_id      = number
    hostname   = string
    ip_address = string
    cpu_cores  = number
    memory     = number
    swap       = number
    start      = bool
    onboot     = bool
    privileged = bool
  })
}

variable "nginx_container" {
  description = "Nginx reverse-proxy LXC container configuration"
  type = object({
    vm_id      = number
    hostname   = string
    ip_address = string
    cpu_cores  = number
    memory     = number
    swap       = number
    start      = bool
    onboot     = bool
    privileged = bool
  })
}

variable "net_services_container" {
  description = "Network services (DNS, etc.) LXC container configuration"
  type = object({
    vm_id      = number
    hostname   = string
    ip_address = string
    dns_server = string
    cpu_cores  = number
    memory     = number
    swap       = number
    start      = bool
    onboot     = bool
    privileged = bool
  })
}

variable "gitlab_container" {
  description = "GitLab LXC container configuration"
  type = object({
    vm_id      = number
    hostname   = string
    ip_address = string
    cpu_cores  = number
    memory     = number
    swap       = number
    start      = bool
    onboot     = bool
    privileged = bool
  })
}

# ---------------------------------------------------------------------------
# VM definitions
# ---------------------------------------------------------------------------

variable "vm_template_id" {
  description = "VM template ID for QEMU/KVM clones"
  type        = number
}

# variable "vm_username" {
#   description = "Cloud-init username for VMs"
#   type        = string
# }

# variable "vm_password" {
#   description = "Cloud-init password for VMs"
#   type        = string
#   sensitive   = true
# }

variable "vm_cpu_cores" {
  description = "Default CPU cores for Ubuntu VMs"
  type        = number
}

variable "vm_memory" {
  description = "Default memory (MB) for Ubuntu VMs"
  type        = number
}

variable "vm_start" {
  description = "Whether Ubuntu VMs should start after creation"
  type        = bool
}

variable "ubuntu_vms" {
  description = "List of generic Ubuntu VMs"
  type = list(object({
    vm_id      = number
    hostname   = string
    ip_address = string
  }))
}

variable "k3s_vms" {
  description = "List of K3s cluster node VMs"
  type = list(object({
    vm_id      = number
    hostname   = string
    ip_address = string
    cpu_cores  = number
    memory     = number
    disk_size  = number
  }))
}
