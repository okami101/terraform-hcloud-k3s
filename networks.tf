resource "hcloud_network" "network" {
  name     = "network"
  ip_range = "10.0.0.0/16"
}

resource "hcloud_network_subnet" "network_subnet" {
  network_id   = hcloud_network.network.id
  type         = "cloud"
  network_zone = var.network_zone
  ip_range     = "10.0.0.0/16"
}

resource "hcloud_firewall" "firewall_private" {
  name = "firewall-private"
}

resource "hcloud_firewall" "firewall_bastion" {
  name = "firewall-bastion"
  rule {
    direction  = "in"
    port       = var.ssh_port
    protocol   = "tcp"
    source_ips = var.my_ip_addresses
  }
}

resource "hcloud_firewall" "firewall_controllers" {
  name = "firewall-controllers"
  rule {
    direction  = "in"
    port       = "6443"
    protocol   = "tcp"
    source_ips = var.my_ip_addresses
  }
}
