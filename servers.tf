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
  user_data = templatefile("${path.module}/cloud-init.tftpl", {
    server_timezone = var.server_timezone
    server_locale   = var.server_locale
    server_packages = var.server_packages
    cluster_name    = var.cluster_name
    cluster_user    = var.cluster_user
    public_ssh_key  = var.my_public_ssh_key
    channel         = var.k3s_channel
    token           = random_password.k3s_token.result
    bastion_ip      = local.bastion_server.ip
    is_bastion      = each.value.name == local.bastion_server_name
    ssh_port        = var.ssh_port
    minion_id       = each.value.name
    is_server       = each.value.role == "controller"
    k3s_config = base64encode(yamlencode(
      merge(
        each.value.role == "controller" ? local.k3s_server_config : {},
        each.value.role == "controller" ? local.etcd_s3_snapshots : {},
        {
          flannel-iface = each.value.private_interface
          node-ip       = each.value.ip
          node-taint    = each.value.taints
          kubelet-arg   = var.kubelet_args
        }
      )
    ))
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

resource "hcloud_volume" "volumes" {
  for_each  = { for i, s in local.servers : s.name => s if s.volume_size >= 10 }
  name      = "${var.cluster_name}-volume-${each.key}"
  size      = each.value.volume_size
  server_id = hcloud_server.servers[each.key].id
  automount = true
  format    = "ext4"
}
