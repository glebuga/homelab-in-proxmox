variable "vm_template_id" {
  type = number
}

variable "vm_username" {
  type = string
}

variable "vm_password" {
  type      = string
  sensitive = true
}

variable "vm_cpu_cores" {
  type = number
}

variable "vm_memory" {
  type = number
}

variable "vm_start" {
  type = bool
}

variable "ubuntu_vms" {
  type = list(object({
    vm_id      = number
    hostname   = string
    ip_address = string
  }))
}