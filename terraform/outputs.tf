output "opnsense_wan_ip" {
  value       = try(module.firewall.network_interfaces[0].addresses[0], "Lease pending...")
  description = "Management WAN IP assigned to the OPNsense gateway by libvirt NAT"
}

output "infrastructure_map" {
  value = {
    firewall = {
      name    = module.firewall.vm_name
      wan_net = "Host NAT (192.168.122.0/24)"
      lan_net = "Internal Gateway (192.168.42.1/24)"
    }
    services_server = {
      name    = module.ubuntu_server.vm_name
      network = "Internal LAN (DHCP via OPNsense)"
    }
    workstation_desktop = {
      name    = module.ubuntu_desktop.vm_name
      network = "Internal LAN (DHCP via OPNsense)"
    }
  }
  description = "Overview of the deployed infrastructure nodes and network roles"
}

