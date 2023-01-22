resource "hcloud_network" "network" {
  name     = "network"
  ip_range = "10.0.0.0/16"
}

resource "hcloud_network_subnet" "network_subnet" {
  network_id   = hcloud_network.network.id
  type         = "server"
  network_zone = "eu-central"
  ip_range     = "10.0.0.0/16"
}

resource "hcloud_load_balancer" "lb" {
  name               = "${var.cluster_name}-lb"
  load_balancer_type = var.lb_type
  location           = var.server_location
}

resource "hcloud_load_balancer_network" "lb_network" {
  load_balancer_id = hcloud_load_balancer.lb.id
  network_id       = hcloud_network.network.id
  ip               = "10.0.0.100"
}

resource "hcloud_load_balancer_service" "lb_services" {
  for_each         = { for i, s in var.lb_services : s.port => s }
  load_balancer_id = hcloud_load_balancer.lb.id
  protocol         = coalesce(each.value.protocol, "http")
  listen_port      = each.value.port
  destination_port = each.value.target_port
  proxyprotocol    = coalesce(each.value.proxyprotocol, false)
}

resource "hcloud_load_balancer_target" "lb_targets" {
  for_each         = { for i, t in local.servers : t.name => t if t.role == var.lb_target }
  type             = "server"
  load_balancer_id = hcloud_load_balancer.lb.id
  server_id        = hcloud_server.servers[each.key].id
  use_private_ip   = true

  depends_on = [
    hcloud_load_balancer_network.lb_network,
    hcloud_server_network.servers
  ]
}

resource "hcloud_firewall" "firewall_private" {
  name = "firewall-private"
}

resource "hcloud_firewall" "firewall_bastion" {
  name = "firewall-bastion"
  rule {
    direction  = "in"
    port       = "2222"
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
