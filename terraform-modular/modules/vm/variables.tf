variable "proxmox_node" {
  description = "Proxmox node name where VMs will be created"
  type        = string
}

variable "vm_template_id" {
  description = "Proxmox VM template ID to clone from"
  type        = number
}

# variable "vm_username" {
#   description = "Cloud-init username"
#   type        = string
# }

# variable "vm_password" {
#   description = "Cloud-init password"
#   type        = string
#   sensitive   = true
# }

variable "gateway" {
  description = "Default gateway for VMs"
  type        = string
}

variable "search_domain" {
  description = "DNS search domain"
  type        = string
}

variable "dns_servers" {
  description = "DNS servers for cloud-init"
  type        = list(string)
}

variable "started" {
  description = "Whether VMs should be started after creation"
  type        = bool
  default     = false
}

variable "on_boot" {
  description = "Whether VMs should start on host boot"
  type        = bool
  default     = false
}

variable "cpu_type" {
  description = "CPU type (e.g. host, kvm64); leave null to use provider default"
  type        = string
  default     = null
}

variable "network_model" {
  description = "Network device model (e.g. virtio); leave null to use provider default"
  type        = string
  default     = null
}

variable "scsi_hardware" {
  description = "SCSI hardware type; required when attaching additional disks"
  type        = string
  default     = null
}

variable "default_cpu_cores" {
  description = "Default CPU cores when not specified per VM"
  type        = number
  default     = null
}

variable "default_memory" {
  description = "Default memory in MB when not specified per VM"
  type        = number
  default     = null
}

variable "vms" {
  description = "Map of VMs keyed by vm_id"
  type = map(object({
    hostname   = string
    ip_address = string
    cpu_cores  = optional(number)
    memory     = optional(number)
    disk_size  = optional(number)
  }))
}
