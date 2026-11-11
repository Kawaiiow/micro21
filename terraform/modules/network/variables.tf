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
