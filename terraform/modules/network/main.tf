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

# Strictly required management network for host SSH access (bridge or host-only NAT)
resource "libvirt_network" "management" {
  name      = var.management_name
  mode      = var.management_mode
  bridge    = var.management_mode == "bridge" ? var.management_bridge : null
  domain    = var.management_mode != "bridge" ? var.management_domain : null
  addresses = var.management_mode != "bridge" ? [var.management_cidr] : null

  dynamic "dhcp" {
    for_each = var.management_mode != "bridge" ? [1] : []
    content {
      enabled = true
    }
  }

  dynamic "dns" {
    for_each = var.management_mode != "bridge" ? [1] : []
    content {
      enabled = true
    }
  }
}


