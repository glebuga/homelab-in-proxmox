resource "proxmox_virtual_environment_vm" "ubuntu_vm" {

  for_each = {
    for vm in var.ubuntu_vms : vm.vm_id => vm
  }

  node_name = var.proxmox_node
  vm_id     = each.value.vm_id
  name      = each.value.hostname

  clone {
    vm_id = var.vm_template_id
  }

  started = var.vm_start

  cpu {
    cores = var.vm_cpu_cores
  }

  memory {
    dedicated = var.vm_memory
  }

  network_device {
    bridge = "vmbr0"
  }

  initialization {

    dns {
      servers = [var.dns_server]
      domain  = var.search_domain
    }

    ip_config {
      ipv4 {
        address = each.value.ip_address
        gateway = var.gateway
      }
    }

    user_account {
      username = var.vm_username
      password = var.vm_password
    }
  }
}