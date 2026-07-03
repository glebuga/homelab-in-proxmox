resource "proxmox_virtual_environment_container" "nginx_bpg" {
  node_name = "proxmox"
  vm_id     = 107

  clone {
    vm_id = 900
  }

  started       = true
  start_on_boot = true
  unprivileged  = true

  initialization {
    hostname = "nginx"

    ip_config {
      ipv4 {
        address = "10.0.0.107/24"
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