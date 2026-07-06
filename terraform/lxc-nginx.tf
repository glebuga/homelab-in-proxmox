resource "proxmox_virtual_environment_container" "nginx_bpg" {

  node_name = var.proxmox_node
  vm_id     = var.nginx_container.vm_id

  clone {
    vm_id = var.template_id
  }

  started       = var.nginx_container.start
  start_on_boot = var.nginx_container.onboot
  unprivileged  = !var.nginx_container.privileged

  initialization {
    hostname = var.nginx_container.hostname

    dns {
      servers = [var.dns_server]
      domain  = var.search_domain
    }

    ip_config {
      ipv4 {
        address = var.nginx_container.ip_address
        gateway = var.gateway
      }
    }
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  cpu {
    cores = var.nginx_container.cpu_cores
  }

  memory {
    dedicated = var.nginx_container.memory
    swap      = var.nginx_container.swap
  }
}