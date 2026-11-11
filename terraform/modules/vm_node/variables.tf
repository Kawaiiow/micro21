variable "vm_name" {
  type        = string
  description = "Hostname and libvirt domain name"
}

variable "memory_mb" {
  type        = number
  default     = 2048
  description = "RAM allocated to the domain in MiB"
}

variable "vcpu_count" {
  type        = number
  default     = 2
  description = "Number of virtual CPUs"
}

variable "pool_name" {
  type        = string
  description = "Target libvirt storage pool name"
}

variable "base_volume_id" {
  type        = string
  description = "Source base volume ID for Copy-on-Write cloning"
}

variable "disk_size" {
  type        = number
  default     = 21474836480 # 20 GB
  description = "Root disk volume size in bytes"
}

variable "user_data" {
  type        = string
  default     = null
  description = "Rendered cloud-init user-data string; omit for non-cloud-init images like OPNsense"
}

variable "graphics_type" {
  type        = string
  default     = "vnc"
  description = "Graphics backend (vnc or spice)"
}

variable "network_interfaces" {
  type = list(object({
    network_id     = optional(string)
	bridge		   = optional(string)
    wait_for_lease = optional(bool, false)
  }))
  default = []
  description = "Ordered list of network interfaces attached to the VM"
}

