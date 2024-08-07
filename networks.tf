resource "hcloud_network" "network" {
  name     = "${var.cluster_name}-network"
  ip_range = "10.${var.network_index}.0.0/16"
}

resource "hcloud_network_subnet" "network_subnet" {
  for_each     = { for i, s in local.subnets : s.name => s }
  network_id   = hcloud_network.network.id
  type         = "cloud"
  network_zone = var.network_zone
  ip_range     = each.value.ip
}

resource "hcloud_firewall" "firewall_bastion" {
  count = var.enable_dedicated_bastion ? 1 : 0
  name  = "${coalesce(var.bastion_name, var.cluster_name)}-bastion"
  rule {
    direction  = "in"
    port       = var.ssh_port
    protocol   = "tcp"
    source_ips = var.my_ip_addresses
  }
  rule {
    direction  = "in"
    port       = var.bastion_wireguard_port
    protocol   = "udp"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
  rule {
    direction  = "in"
    port       = "80"
    protocol   = "tcp"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
  rule {
    direction  = "in"
    port       = var.bastion_wireguard_ui_port
    protocol   = "tcp"
    source_ips = var.my_ip_addresses
  }
}

resource "hcloud_firewall" "firewall_controllers" {
  name = "${var.cluster_name}-controllers"
  dynamic "rule" {
    for_each = var.enable_dedicated_bastion ? [] : [var.ssh_port, "6443"]
    content {
      direction  = "in"
      port       = rule.value
      protocol   = "tcp"
      source_ips = var.my_ip_addresses
    }
  }
}

resource "hcloud_firewall" "firewall_workers" {
  name = "${var.cluster_name}-workers"

  dynamic "rule" {
    for_each = { for i, p in var.allowed_inbound_ports : i => p }
    content {
      port       = rule.value
      direction  = "in"
      protocol   = "tcp"
      source_ips = ["0.0.0.0/0", "::/0"]
    }
  }
}

resource "hcloud_load_balancer" "lbs" {
  for_each           = { for l in local.load_balancers : l.name => l }
  name               = "${var.cluster_name}-${each.key}"
  load_balancer_type = each.value.type
  location           = each.value.location
}

resource "hcloud_load_balancer_network" "lb_networks" {
  for_each         = { for l in local.load_balancers : l.name => l }
  load_balancer_id = hcloud_load_balancer.lbs[each.key].id
  network_id       = hcloud_network.network.id
  ip               = each.value.ip
}

resource "hcloud_load_balancer_target" "lb_targets" {
  for_each         = { for i, t in local.servers : t.name => t if t.lb_type != null }
  type             = "server"
  load_balancer_id = hcloud_load_balancer.lbs[each.value.role].id
  server_id        = hcloud_server.servers[each.key].id
  use_private_ip   = true

  depends_on = [
    hcloud_load_balancer_network.lb_networks,
    hcloud_server_network.servers
  ]
}
