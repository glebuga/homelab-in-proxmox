resource "proxmox_virtual_environment_container" "docker_bpg" {
  depends_on = [proxmox_virtual_environment_container.nginx_bpg]

  node_name = var.proxmox_node
  vm_id     = var.docker_container.vm_id

  clone {
    vm_id = var.template_id
  }

  started       = var.docker_container.start
  start_on_boot = var.docker_container.onboot
  unprivileged  = !var.docker_container.privileged

  features {
    nesting = true
  }

  initialization {

    hostname = var.docker_container.hostname

    dns {
      servers = [var.dns_server]
      domain  = var.search_domain
    }

    ip_config {
      ipv4 {
        address = var.docker_container.ip_address
        gateway = var.gateway
      }
    }
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  cpu {
    cores = var.docker_container.cpu_cores
  }

  memory {
    dedicated = var.docker_container.memory
    swap      = var.docker_container.swap
  }
}