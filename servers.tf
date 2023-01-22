resource "hcloud_server" "servers" {
  for_each                   = { for i, s in local.servers : s.name => s }
  name                       = "${var.cluster_name}-${each.value.name}"
  image                      = var.server_image
  location                   = var.server_location
  server_type                = each.value.server_type
  ignore_remote_firewall_ids = true
  firewall_ids = [
    hcloud_firewall.firewall_private.id
  ]
  ssh_keys = [
    var.my_public_ssh_name
  ]
  depends_on = [
    hcloud_network_subnet.network_subnet
  ]
  user_data = templatefile("${path.module}/init_${each.value.name == local.bastion_server_name ? "server" : "agent"}.tftpl", {
    server_timezone   = var.server_timezone
    server_locale     = var.server_locale
    server_packages   = var.server_packages
    minion_id         = each.value.name
    cluster_name      = var.cluster_name
    cluster_user      = var.cluster_user
    ssh_port          = var.ssh_port
    public_ssh_key    = var.my_public_ssh_key
    servers           = local.servers
    disabled_services = "traefik"
    channel           = var.k3s_channel
    interface         = each.value.private_interface
    token             = random_password.k3s_token.result
    controller_ip     = local.bastion_server.ip
    node_ip           = each.value.ip
    role              = each.value.role
    args              = { for i, a in var.kubelet_args : a.key => a.value }
  })

  lifecycle {
    ignore_changes = [
      user_data,
      ssh_keys
    ]
  }
}

resource "hcloud_server_network" "servers" {
  for_each   = { for i, s in local.servers : s.name => s }
  server_id  = hcloud_server.servers[each.value.name].id
  network_id = hcloud_network.network.id
  ip         = each.value.ip
}
