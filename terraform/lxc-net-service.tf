resource "proxmox_virtual_environment_container" "net_services_bpg" {
  depends_on = [proxmox_virtual_environment_container.docker_bpg]

  node_name = var.proxmox_node
  vm_id     = var.net_services_container.vm_id

  clone {
    vm_id = var.template_id
  }

  started       = var.net_services_container.start
  start_on_boot = var.net_services_container.onboot
  unprivileged  = !var.net_services_container.privileged

  initialization {
    hostname = var.net_services_container.hostname

    dns {
      servers = [var.net_services_container.dns_server]
      domain  = var.search_domain
    }

    ip_config {
      ipv4 {
        address = var.net_services_container.ip_address
        gateway = var.gateway
      }
    }
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  cpu {
    cores = var.net_services_container.cpu_cores
  }

  memory {
    dedicated = var.net_services_container.memory
    swap      = var.net_services_container.swap
  }
}