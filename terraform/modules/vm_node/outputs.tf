output "vm_id" {
  value       = libvirt_domain.instance.id
  description = "Libvirt domain identifier"
}

output "vm_name" {
  value       = libvirt_domain.instance.name
  description = "Virtual machine domain name"
}

output "network_interfaces" {
  value       = libvirt_domain.instance.network_interface
  description = "Interface configuration list including assigned IP addresses"
}

