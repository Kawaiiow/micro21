variable "wan_name" {
  type        = string
  default     = "fw-wan-net"
  description = "Name of the WAN libvirt NAT network"
}

variable "wan_cidr" {
  type        = string
  default     = "192.168.122.0/24"
  description = "CIDR subnet assigned to the WAN bridge"
}

variable "wan_domain" {
  type        = string
  default     = "mini21.com"
  description = "Domain name for the WAN bridge"
}

variable "lan_name" {
  type        = string
  default     = "fw-lan-net"
  description = "Name of the isolated LAN bridge"
}

variable "management_name" {
  type        = string
  default     = "fw-mgmt-net"
  description = "Name of the libvirt management network"
}

variable "management_mode" {
  type        = string
  default     = "bridge"
  description = "Mode for management network: 'bridge' (uses host Linux bridge like br0) or 'nat' (host-only/NAT network with host SSH access)"
}

variable "management_bridge" {
  type        = string
  default     = "br0"
  description = "Host Linux bridge device name (required when management_mode is 'bridge')"
}

variable "management_cidr" {
  type        = string
  default     = "192.168.200.0/24"
  description = "CIDR subnet assigned to management network when management_mode is 'nat'"
}

variable "management_domain" {
  type        = string
  default     = "mgmt.local"
  description = "Domain name for management network when management_mode is 'nat'"
}

