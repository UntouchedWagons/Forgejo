
terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.121.0" # Use the latest stable version available
    }
    sops = {
      source  = "carlpett/sops"
      version = "~> 1.4.0" # Use the latest stable version
    }
  }
}

variable "proxmox_api_url" {
  type    = string
  default = "https://proxmox.internal.untouchedwagons.com:8006" # Change to your PVE Node IP
}

provider "sops" {}

data "sops_file" "secret_credentials" {
  source_file = "secrets.enc.yaml"
}

provider "proxmox" {
  endpoint  = var.proxmox_api_url
  api_token = data.sops_file.secret_credentials.data["proxmox_api_token"]
  insecure  = false
}
