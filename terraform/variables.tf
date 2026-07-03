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