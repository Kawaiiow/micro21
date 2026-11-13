output "opnsense_wan_ip" {
  value       = try(module.firewall.network_interfaces[0].addresses[0], "Lease pending...")
  description = "Management WAN IP assigned to the OPNsense gateway by libvirt NAT"
}

output "management_ips" {
  value = {
    firewall       = var.opnsense_management_ip
    ubuntu_server  = try(module.ubuntu_server.network_interfaces[1].addresses[0], "Lease pending...")
    ubuntu_desktop = try(module.ubuntu_desktop.network_interfaces[1].addresses[0], "Lease pending...")
  }
  description = "Management network IP addresses assigned to virtual machines"
}

output "ssh_commands" {
  value = {
    firewall       = "ssh root@${var.opnsense_management_ip}"
    ubuntu_server  = "ssh sysadmin@${try(module.ubuntu_server.network_interfaces[1].addresses[0], "<pending>")}"
    ubuntu_desktop = "ssh bocal@${try(module.ubuntu_desktop.network_interfaces[1].addresses[0], "<pending>")}"
  }
  description = "Ready-to-use SSH connection commands for deployed instances"
}

output "infrastructure_map" {
  value = {
    firewall = {
      name          = module.firewall.vm_name
      wan_net       = "Host NAT (192.168.100.0/24)"
      lan_net       = "Internal Gateway (192.168.42.1/24)"
      management_ip = var.opnsense_management_ip
    }
    services_server = {
      name          = module.ubuntu_server.vm_name
      network       = "Internal LAN (DHCP via OPNsense)"
      management_ip = try(module.ubuntu_server.network_interfaces[1].addresses[0], "Lease pending...")
    }
    workstation_desktop = {
      name          = module.ubuntu_desktop.vm_name
      network       = "Internal LAN (DHCP via OPNsense)"
      management_ip = try(module.ubuntu_desktop.network_interfaces[1].addresses[0], "Lease pending...")
    }
  }
  description = "Overview of the deployed infrastructure nodes and network roles"
}


