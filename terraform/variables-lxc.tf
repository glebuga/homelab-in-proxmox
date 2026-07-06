variable "docker_container" {
  type = object({
    vm_id        = number
    hostname     = string
    ip_address   = string
    cpu_cores    = number
    memory       = number
    swap         = number
    start        = bool
    onboot       = bool
    privileged   = bool
  })
}

variable "nginx_container" {
  type = object({
    vm_id        = number
    hostname     = string
    ip_address   = string
    cpu_cores    = number
    memory       = number
    swap         = number
    start        = bool
    onboot       = bool
    privileged   = bool
  })
}

variable "net_services_container" {
  type = object({
    vm_id        = number
    hostname     = string
    ip_address   = string
    dns_server   = string
    cpu_cores    = number
    memory       = number
    swap         = number
    start        = bool
    onboot       = bool
    privileged   = bool
  })
}