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

variable "ubuntu_vm" {
  type = object({
    vm_id      = number
    hostname   = string
    ip_address = string
    cpu_cores  = number
    memory     = number
    start      = bool
  })
}