# ---------------------------------------------------------------------------
# LXC containers
# Creation order preserved via depends_on (nginx -> docker -> net_services)
# ---------------------------------------------------------------------------

module "nginx" {
  source = "./modules/lxc"

  proxmox_node  = var.proxmox_node
  template_id   = var.template_id
  vm_id         = var.nginx_container.vm_id
  hostname      = var.nginx_container.hostname
  ip_address    = var.nginx_container.ip_address
  gateway       = var.gateway
  dns_server    = var.dns_server
  search_domain = var.search_domain
  cpu_cores     = var.nginx_container.cpu_cores
  memory        = var.nginx_container.memory
  swap          = var.nginx_container.swap
  start         = var.nginx_container.start
  onboot        = var.nginx_container.onboot
  privileged    = var.nginx_container.privileged
}

module "docker" {
  source = "./modules/lxc"

  depends_on = [module.nginx]

  proxmox_node    = var.proxmox_node
  template_id     = var.template_id
  vm_id           = var.docker_container.vm_id
  hostname        = var.docker_container.hostname
  ip_address      = var.docker_container.ip_address
  gateway         = var.gateway
  dns_server      = var.dns_server
  search_domain   = var.search_domain
  cpu_cores       = var.docker_container.cpu_cores
  memory          = var.docker_container.memory
  swap            = var.docker_container.swap
  start           = var.docker_container.start
  onboot          = var.docker_container.onboot
  privileged      = var.docker_container.privileged
  enable_nesting  = true
}

module "net_services" {
  source = "./modules/lxc"

  depends_on = [module.docker]

  proxmox_node  = var.proxmox_node
  template_id   = var.template_id
  vm_id         = var.net_services_container.vm_id
  hostname      = var.net_services_container.hostname
  ip_address    = var.net_services_container.ip_address
  gateway       = var.gateway
  dns_server    = var.net_services_container.dns_server
  search_domain = var.search_domain
  cpu_cores     = var.net_services_container.cpu_cores
  memory        = var.net_services_container.memory
  swap          = var.net_services_container.swap
  start         = var.net_services_container.start
  onboot        = var.net_services_container.onboot
  privileged    = var.net_services_container.privileged
}

module "gitlab" {
  source = "./modules/lxc"

  proxmox_node   = var.proxmox_node
  template_id    = var.template_id
  vm_id          = var.gitlab_container.vm_id
  hostname       = var.gitlab_container.hostname
  ip_address     = var.gitlab_container.ip_address
  gateway        = var.gateway
  dns_server     = var.dns_server
  search_domain  = var.search_domain
  cpu_cores      = var.gitlab_container.cpu_cores
  memory         = var.gitlab_container.memory
  swap           = var.gitlab_container.swap
  start          = var.gitlab_container.start
  onboot         = var.gitlab_container.onboot
  privileged     = var.gitlab_container.privileged
  enable_nesting = true
  disk_size      = 30
}

# ---------------------------------------------------------------------------
# Virtual machines
# ---------------------------------------------------------------------------

module "ubuntu_vms" {
  source = "./modules/vm"

  proxmox_node      = var.proxmox_node
  vm_template_id    = var.vm_template_id
  # vm_username       = var.vm_username
  # vm_password       = var.vm_password
  gateway           = var.gateway
  search_domain     = var.search_domain
  dns_servers       = [var.dns_server]
  started           = var.vm_start
  default_cpu_cores = var.vm_cpu_cores
  default_memory    = var.vm_memory

  vms = {
    for vm in var.ubuntu_vms : tostring(vm.vm_id) => {
      hostname   = vm.hostname
      ip_address = vm.ip_address
    }
  }
}

module "k3s_vms" {
  source = "./modules/vm"

  proxmox_node    = var.proxmox_node
  vm_template_id  = var.vm_template_id
  # vm_username     = var.vm_username
  # vm_password     = var.vm_password
  gateway         = var.gateway
  search_domain   = var.search_domain
  dns_servers     = [var.router_dns_server]
  cpu_type        = "host"
  network_model   = "virtio"
  scsi_hardware   = "virtio-scsi-single"

  vms = {
    for vm in var.k3s_vms : tostring(vm.vm_id) => {
      hostname   = vm.hostname
      ip_address = vm.ip_address
      cpu_cores  = vm.cpu_cores
      memory     = vm.memory
      disk_size  = vm.disk_size
    }
  }
}
