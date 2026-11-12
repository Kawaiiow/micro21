resource "libvirt_volume" "root_disk" {
  name           = "${var.vm_name}-root.qcow2"
  pool           = var.pool_name
  base_volume_id = var.base_volume_id
  size           = var.disk_size
  format         = "qcow2"
}

resource "libvirt_cloudinit_disk" "init_disk" {
  count     = var.user_data != null ? 1 : 0
  name      = "${var.vm_name}-cloudinit.iso"
  pool      = var.pool_name
  user_data = var.user_data
}

resource "libvirt_domain" "instance" {
  name   = var.vm_name
  type   = "kvm"
  memory = var.memory_mb
  vcpu   = var.vcpu_count

  cloudinit = var.user_data != null ? libvirt_cloudinit_disk.init_disk[0].id : null

  disk {
    volume_id = libvirt_volume.root_disk.id
  }

  dynamic "network_interface" {
    for_each = var.network_interfaces
    content {
      network_id     = network_interface.value.network_id
      bridge         = network_interface.value.bridge
      wait_for_lease = try(network_interface.value.wait_for_lease, false)
    }
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  graphics {
    type        = var.graphics_type
    listen_type = "address"
    autoport    = true
  }

  dynamic "video" {
    for_each = var.video_type != null ? [var.video_type] : []
    content {
      type = video.value
    }
  }
}

