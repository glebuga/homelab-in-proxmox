resource "proxmox_virtual_environment_vm" "ubuntu_vm" {

  node_name = var.proxmox_node
  vm_id     = var.ubuntu_vm.vm_id
  name      = var.ubuntu_vm.hostname

  clone {
    vm_id = var.vm_template_id
  }

  started = var.ubuntu_vm.start

  cpu {
    cores = var.ubuntu_vm.cpu_cores
  }

  memory {
    dedicated = var.ubuntu_vm.memory
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
        address = var.ubuntu_vm.ip_address
        gateway = var.gateway
      }
    }

    user_account {
      username = var.vm_username
      password = var.vm_password
    }
  }
}