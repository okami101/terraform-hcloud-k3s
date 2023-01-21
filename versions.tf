terraform {
  required_version = ">= 1.3.7"
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.36.2"
    }
  }
}
