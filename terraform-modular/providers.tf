terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.110.0"
    }
  }
}

provider "proxmox" {
  endpoint  = var.pm_api_url
  api_token = var.pm_api_token
  insecure  = true # Отключает проверку SSL-сертификата
}
