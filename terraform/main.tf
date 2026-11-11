# Storage & Disk Images
resource "libvirt_pool" "vm_pool" {
  name = "${local.name_prefix}-pool"
  type = "dir"
  path = var.storage_pool_path
}

resource "libvirt_volume" "ubuntu_base" {
  name   = "${local.name_prefix}-ubuntu-26.04-base.qcow2"
  pool   = libvirt_pool.vm_pool.name
  source = var.ubuntu_image_url
  format = "qcow2"
}

resource "libvirt_volume" "opnsense_base" {
  name   = "${local.name_prefix}-opnsense-base.qcow2"
  pool   = libvirt_pool.vm_pool.name
  source = var.opnsense_image_url
  format = "qcow2"
}
 
# Network Infrastructure Module
module "network" {
  source = "./modules/network"

  wan_name   = "${local.name_prefix}-wan-net"
  wan_cidr   = "192.168.100.0/24"
  wan_domain = "${local.name_prefix}.com"
  lan_name   	= "${local.name_prefix}-lan-net"
}

# OPNsense Firewall (Gateway)
module "firewall" {
  source = "./modules/vm_node"

  vm_name        = "${local.name_prefix}-opnsense-fw"
  memory_mb      = 4096
  vcpu_count     = 2
  pool_name      = libvirt_pool.vm_pool.name
  base_volume_id = libvirt_volume.opnsense_base.id
  disk_size      = 21474836480 # 20 GB
  user_data      = null        # FreeBSD-based, no cloud-init

  network_interfaces = [
    {
      network_id     = module.network.wan_network_id # vtnet0 (WAN)
      wait_for_lease = false
    },
    {
      network_id     = module.network.lan_network_id # vtnet1 (LAN)
      wait_for_lease = false
    },
	{
	  bridge		 = var.management_interface
	  wait_for_lease = false
	}
  ]
}

# Ubuntu Server
module "ubuntu_server" {
  source = "./modules/vm_node"

  vm_name        = "${local.name_prefix}-srv-01"
  memory_mb      = 2
  vcpu_count     = 2
  pool_name      = libvirt_pool.vm_pool.name
  base_volume_id = libvirt_volume.ubuntu_base.id
  disk_size      = 10737418240 # 10 GB

  user_data = templatefile("${path.module}/templates/server_init.cfg", {
    hostname = "srv-ubuntu-01"
    ssh_key  = file(pathexpand(var.ssh_public_key_path))
  })

  network_interfaces = [
    {
      network_id     = module.network.lan_network_id
      wait_for_lease = false
    }
  ]

  depends_on = [module.firewall]
}

# Ubuntu Desktop
module "ubuntu_desktop" {
  source = "./modules/vm_node"

  vm_name        = "${local.name_prefix}-ws-01"
  memory_mb      = 4096 # 6 GB RAM for desktop GUI
  vcpu_count     = 2
  pool_name      = libvirt_pool.vm_pool.name
  base_volume_id = libvirt_volume.ubuntu_base.id
  disk_size      = 21474836480 # 20 GB

  user_data = templatefile("${path.module}/templates/desktop_init.cfg", {
    hostname = "z0t0c0"
    username = "bocal"
    ssh_key  = file(pathexpand(var.ssh_public_key_path))
  })

  network_interfaces = [
    {
      network_id     = module.network.lan_network_id
      wait_for_lease = false
    }
  ]

  depends_on = [module.firewall]
}

