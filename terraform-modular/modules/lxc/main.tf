resource "proxmox_virtual_environment_container" "this" {
  node_name = var.proxmox_node
  vm_id     = var.vm_id

  clone {
    vm_id = var.template_id
  }

  started       = var.start
  start_on_boot = var.onboot
  unprivileged  = !var.privileged

  dynamic "features" {
    for_each = var.enable_nesting ? [1] : []
    content {
      nesting = true
    }
  }

  initialization {
    hostname = var.hostname

    dns {
      servers = [var.dns_server]
      domain  = var.search_domain
    }

    ip_config {
      ipv4 {
        address = var.ip_address
        gateway = var.gateway
      }
    }
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  cpu {
    cores = var.cpu_cores
  }

  memory {
    dedicated = var.memory
    swap      = var.swap
  }

  dynamic "disk" {
    for_each = var.disk_size != null ? [1] : []
    content {
      datastore_id = "local-lvm"
      size         = var.disk_size
    }
  }
}
