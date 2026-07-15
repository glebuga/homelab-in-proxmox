variable "proxmox_node" {
  description = "Proxmox node name where the container will be created"
  type        = string
}

variable "template_id" {
  description = "Proxmox container template ID to clone from"
  type        = number
}

variable "vm_id" {
  description = "Unique VM ID for the LXC container"
  type        = number
}

variable "hostname" {
  description = "Container hostname"
  type        = string
}

variable "ip_address" {
  description = "Static IPv4 address with CIDR notation"
  type        = string
}

variable "gateway" {
  description = "Default gateway for the container"
  type        = string
}

variable "dns_server" {
  description = "DNS server for container initialization"
  type        = string
}

variable "search_domain" {
  description = "DNS search domain"
  type        = string
}

variable "cpu_cores" {
  description = "Number of CPU cores"
  type        = number
}

variable "memory" {
  description = "Dedicated memory in MB"
  type        = number
}

variable "swap" {
  description = "Swap memory in MB"
  type        = number
}

variable "start" {
  description = "Whether the container should be started after creation"
  type        = bool
}

variable "onboot" {
  description = "Whether the container should start on host boot"
  type        = bool
}

variable "privileged" {
  description = "Whether the container runs in privileged mode"
  type        = bool
}

variable "enable_nesting" {
  description = "Enable nesting feature (required for Docker-in-LXC)"
  type        = bool
  default     = false
}

variable "disk_size" {
  description = "Additional root disk size in GB; omit to use template default"
  type        = number
  default     = null
}
