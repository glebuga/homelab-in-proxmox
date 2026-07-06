variable "pm_api_url" {
  description = "URL для API Proxmox"
  type        = string
  default     = "https://192.168.0.200:8006/"
}

variable "pm_api_token" {
  type      = string
  sensitive = true
}

variable "proxmox_node" {
  type = string
}

variable "template_id" {
  type = number
}

variable "dns_server" {
  type = string
}

variable "router_dns_server" {
  type = string
}

variable "search_domain" {
  type = string
}

variable "gateway" {
  type = string
}