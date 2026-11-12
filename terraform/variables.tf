variable "project" {
  type        = string
  default     = "mini21"
  description = "Project or workload identifier"
}

variable "libvirt_uri" {
  type        = string
  default     = "qemu:///system"
  description = "Connection URI for libvirtd"
}

variable "storage_pool_path" {
  type        = string
  default     = "/var/lib/libvirt/images/"
  description = "Host directory path for storage pool"
}

variable "ubuntu_image_url" {
  type        = string
  default     = "https://cloud-images.ubuntu.com/releases/resolute/release/ubuntu-26.04-server-cloudimg-amd64.img"
  description = "Ubuntu 26.04LTS base cloud image URL"
}

variable "opnsense_image_url" {
  type        = string
  default     = "images/OPNsense-26.7-configured.qcow2"
  description = "Path to pre-configured OPNsense QCOW2 disk"
}

variable "management_interface" {
  type        = string
  default     = "br0"
  description = "Interface for management the network"
}

variable "ssh_public_key_path" {
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
  description = "Path to SSH public key for instance access"
}

