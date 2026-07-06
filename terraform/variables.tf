variable "pm_api_url" {
  description = "URL для API Proxmox"
  type        = string
  default     = "https://192.168.0.200:8006/"
}

variable "pm_api_token" {
  description = "Токен доступа к Proxmox API"
  type        = string
  sensitive   = true
}

variable "dns_server" {
  type    = string
  default = "10.0.0.110"
}

variable "search_domain" {
  type    = string
  default = "lab.local"
}