resource "proxmox_virtual_environment_container" "net_services_bpg" {
  depends_on = [proxmox_virtual_environment_container.docker_bpg]

  node_name = "proxmox"
  vm_id     = 110

  clone {
    vm_id = 900
  }

  started       = true
  start_on_boot = true
  unprivileged  = true

  initialization {
    hostname = "net-services"

    dns {
      servers = ["192.168.0.1"]
      domain  = var.search_domain
    }

    ip_config {
      ipv4 {
        address = "10.0.0.110/24"
        gateway = "10.0.0.1"
      }
    }
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  cpu {
    cores = 1
  }

  memory {
    dedicated = 512
    swap      = 512
  }
}