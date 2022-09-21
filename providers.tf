terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
  }

  backend "kubernetes" {
    secret_suffix = "cloud"
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_ssh_key" "default" {
  name       = var.my_public_ssh_name
  public_key = var.my_public_ssh_key
}
