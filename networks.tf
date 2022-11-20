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
  load_balancer_type = "lb11"
  location           = var.server_location
}

resource "hcloud_load_balancer_network" "lb_network" {
  load_balancer_id = hcloud_load_balancer.lb.id
  network_id       = hcloud_network.network.id
  ip               = "10.0.0.100"
}

resource "hcloud_load_balancer_service" "lb_services" {
  for_each         = { for i, port in var.lb_services : port => port }
  load_balancer_id = hcloud_load_balancer.lb.id
  protocol         = "tcp"
  listen_port      = each.value
  destination_port = each.value
  proxyprotocol    = each.value == 443
}

resource "hcloud_load_balancer_target" "lb_targets" {
  for_each         = { for i, t in local.servers : t.name => t if t.role == var.lb_server_role }
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

resource "hcloud_firewall_attachment" "deny_all" {
  firewall_id = hcloud_firewall.firewall_private.id
  server_ids  = [for s in local.servers : hcloud_server.servers[s.name].id]
}

resource "hcloud_firewall_attachment" "bastion" {
  firewall_id = hcloud_firewall.firewall_bastion.id
  server_ids  = [hcloud_server.servers[local.bastion_server_name].id]
}

resource "hcloud_firewall_attachment" "controllers" {
  firewall_id = hcloud_firewall.firewall_controllers.id
  server_ids  = [for s in local.servers : hcloud_server.servers[s.name].id if s.role == "controller"]
}
