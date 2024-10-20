resource "hcloud_server" "servers" {
  for_each    = { for i, s in local.servers : s.name => s }
  name        = "${var.cluster_name}-${each.value.name}"
  image       = var.server_image
  server_type = each.value.server_type
  location    = each.value.location
  public_net {
    ipv4_enabled = var.enable_ipv4
    ipv6_enabled = var.enable_ipv6
  }
  firewall_ids = each.value.role == "controller" ? [
    hcloud_firewall.firewall_controllers.id
    ] : [
    hcloud_firewall.firewall_workers.id
  ]
  ssh_keys = var.my_ssh_key_names
  depends_on = [
    hcloud_network_subnet.network_subnet
  ]
  user_data = templatefile("${path.module}/cloud-init-k3s.tftpl", {
    server_timezone     = var.server_timezone
    server_locale       = var.server_locale
    server_packages     = var.server_packages
    cluster_name        = var.cluster_name
    cluster_user        = var.cluster_user
    ssh_port            = var.ssh_port
    public_ssh_keys     = var.my_public_ssh_keys
    channel             = var.k3s_channel
    token               = random_password.k3s_token.result
    is_bastion          = !var.enable_dedicated_bastion && each.value.ip == local.first_controller_ip
    bastion_ip          = local.bastion_ip
    is_first_controller = each.value.ip == local.first_controller_ip
    first_controller_ip = local.first_controller_ip
    minion_id           = each.value.name
    is_server           = each.value.role == "controller"
    k3s_config = base64encode(each.value.role == "controller" ? yamlencode(
      merge(
        var.control_planes_custom_config,
        {
          flannel-iface = each.value.private_interface
          node-ip       = each.value.ip
          node-label    = each.value.labels
          node-taint    = each.value.taints
          kubelet-arg   = var.kubelet_args
        }
      )) : yamlencode(
      {
        flannel-iface = each.value.private_interface
        node-ip       = each.value.ip
        node-label    = each.value.labels
        node-taint    = each.value.taints
        kubelet-arg   = var.kubelet_args
      }
    ))
  })

  lifecycle {
    ignore_changes = [
      firewall_ids,
      user_data,
      ssh_keys,
      image
    ]
  }
}

resource "hcloud_server_network" "servers" {
  for_each   = { for i, s in local.servers : s.name => s }
  server_id  = hcloud_server.servers[each.value.name].id
  network_id = hcloud_network.network.id
  ip         = each.value.ip
}

resource "hcloud_volume" "volumes" {
  for_each  = { for i, s in local.servers : s.name => s if s.volume_size >= 10 }
  name      = "${var.cluster_name}-${each.value.name}"
  size      = each.value.volume_size
  server_id = hcloud_server.servers[each.key].id
  automount = true
  format    = each.value.volume_format != null ? each.value.volume_format : "ext4"
}
