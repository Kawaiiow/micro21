output "wan_network_id" {
  value       = libvirt_network.wan.id
  description = "ID of the host NAT network"
}

output "lan_network_id" {
  value       = libvirt_network.lan.id
  description = "Identifier of the isolated internal LAN bridge"
}

