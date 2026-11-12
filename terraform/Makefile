.PHONY: bake-image bake-image-overlay init plan apply destroy console-fw console-srv console-ws

# Offline bake: creates a standalone full copy (~2.1 GB) with config.xml injected
bake-image:
	python3 scripts/bake_opnsense_image.py --mode standalone

# Offline bake: creates a lightweight Copy-on-Write overlay (~20 MB) with config.xml injected
bake-image-overlay:
	python3 scripts/bake_opnsense_image.py --mode overlay

# OpenTofu workflow shortcuts
init:
	tofu init

plan:
	tofu plan -var-file=tofu.tfvars

apply:
	tofu apply -var-file=tofu.tfvars

destroy:
	tofu destroy -var-file=tofu.tfvars

# Libvirt console helpers
console-fw:
	virsh --connect qemu:///system console mini21-opnsense-fw

console-srv:
	virsh --connect qemu:///system console mini21-srv-01

console-ws:
	virsh --connect qemu:///system console mini21-ws-01
