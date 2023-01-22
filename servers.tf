resource "hcloud_server" "servers" {
  for_each    = { for i, s in local.servers : s.name => s }
  name        = "${var.cluster_name}-${each.value.name}"
  image       = var.server_image
  location    = var.server_location
  server_type = each.value.server_type
  firewall_ids = concat(
    [hcloud_firewall.firewall_private.id],
    each.value.name == local.bastion_server_name ? [hcloud_firewall.firewall_bastion.id] : [],
    each.value.role == "controller" ? [hcloud_firewall.firewall_controllers.id] : []
  )
  ssh_keys = [
    var.cluster_user
  ]
  depends_on = [
    hcloud_network_subnet.network_subnet
  ]
  user_data = templatefile("${path.module}/init_${each.value.name == local.bastion_server_name ? "bastion" : "default"}.tftpl", {
    global_cloud_config = templatefile("${path.module}/init_global.tftpl", {
      server_timezone = var.server_timezone
      server_locale   = var.server_locale
      server_packages = var.server_packages
      cluster_user    = var.cluster_user
      public_ssh_key  = var.my_public_ssh_key
    }),
    global_runcmd = templatefile("${path.module}/init_global_runcmd.tftpl", {
      ssh_port  = var.ssh_port
      minion_id = each.value.name
      bastion   = each.value.name == local.bastion_server_name
    }),
    global_k3s_config = templatefile("${path.module}/init_global_k3s.tftpl", {
      disabled_components = var.disabled_components
      interface           = each.value.private_interface
      node_ip             = each.value.ip
      role                = each.value.role
      taints              = each.value.taints
      args                = { for i, a in var.kubelet_args : a.key => a.value }
    }),
    cluster_name = var.cluster_name
    servers      = local.servers
    channel      = var.k3s_channel
    token        = random_password.k3s_token.result
    bastion_ip   = local.bastion_server.ip
    role         = each.value.role
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
