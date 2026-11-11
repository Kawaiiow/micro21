# WAN NAT bridge managed by libvirt dnsmasq
resource "libvirt_network" "wan" {
  name      = var.wan_name
  mode      = "nat"
  domain    = var.wan_domain
  addresses = [var.wan_cidr]

  dhcp {
    enabled = true
  }

  dns {
    enabled = true
  }
}

# LAN bridge with zero host DHCP/DNS; pure isolated L2 switch
resource "libvirt_network" "lan" {
  name = var.lan_name
  mode = "none"
}

