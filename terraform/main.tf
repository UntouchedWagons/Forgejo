
resource "proxmox_virtual_environment_vm" "socrates" {
  name          = "Forgejo"
  bios          = "ovmf"
  description   = "Managed by Terraform"
  tags          = ["kubernetes", "terraform", "talos", "linux"]
  node_name     = "proxmox" # Your physical Proxmox node name
  vm_id         = 101
  started       = false
  machine       = "q35"
  scsi_hardware = "virtio-scsi-single"
  boot_order    = ["ide2", "scsi0"]

  # Display Configuration
  vga {
    type   = "virtio"
    memory = "256"
  }

  # System Specs
  cpu {
    cores   = 6
    sockets = 1
    type    = "x86-64-v4"
    numa    = true
  }

  memory {
    dedicated = 8192
  }

  agent {
    enabled = true
  }

  # Disk Configuration
  disk {
    datastore_id = "local-zfs"
    size         = 30 # Gigabytes
    interface    = "scsi0"
    ssd          = true
    discard      = "on"
    file_format  = "raw"
  }

  disk {
    datastore_id = "local-zfs"
    size         = 30 # Gigabytes
    interface    = "scsi1"
    ssd          = true
    discard      = "on"
    file_format  = "raw"
  }

  # Network Configuration
  network_device {
    bridge = "vmbr0"
    mac_address = "BC:24:11:6A:CA:2A"
    vlan_id     = 16
  }

  efi_disk {
    datastore_id      = "local-zfs"
    file_format       = "raw"
    pre_enrolled_keys = false
  }

  cdrom {
    file_id   = "local:iso/Talos-1.14.5-forgejo.iso"
    interface = "ide2"
    enabled   = true
  }
}
