resource "proxmox_virtual_environment_vm" "this" {
  for_each = var.vms

  node_name = var.proxmox_node
  vm_id     = tonumber(each.key)
  name      = each.value.hostname

  clone {
    vm_id = var.vm_template_id
  }

  started = var.started
  on_boot = var.on_boot

  cpu {
    cores = coalesce(each.value.cpu_cores, var.default_cpu_cores)
    type  = var.cpu_type
  }

  memory {
    dedicated = coalesce(each.value.memory, var.default_memory)
  }

  dynamic "disk" {
    for_each = each.value.disk_size != null ? [1] : []
    content {
      datastore_id = "local-lvm"
      size         = each.value.disk_size
      interface    = "scsi0"
    }
  }

  scsi_hardware = var.scsi_hardware

  network_device {
    bridge = "vmbr0"
    model  = var.network_model
  }

  initialization {
    dns {
      servers = var.dns_servers
      domain  = var.search_domain
    }

    ip_config {
      ipv4 {
        address = each.value.ip_address
        gateway = var.gateway
      }
    }

    # user_account {
    #   username = var.vm_username
    #   password = var.vm_password
    # }
  }
}
