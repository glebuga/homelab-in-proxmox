resource "proxmox_virtual_environment_container" "docker_bpg" {
  depends_on = [proxmox_virtual_environment_container.nginx_bpg]

  node_name = "proxmox"
  vm_id     = 105

  clone {
    vm_id = 900
  }

  started       = true
  start_on_boot = true
  unprivileged  = true

  features {
    nesting = true
  }

  initialization {
    hostname = "docker"

    dns {
      servers = [var.dns_server]
      domain  = var.search_domain
    }

    ip_config {
      ipv4 {
        address = "10.0.0.105/24"
        gateway = "10.0.0.1"
      }
    }
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 2048
    swap      = 512
  }
}