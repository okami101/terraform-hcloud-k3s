resource "hcloud_server" "bastion" {
  count        = var.enable_dedicated_bastion ? 1 : 0
  name         = "${coalesce(var.bastion_name, var.cluster_name)}-bastion"
  image        = "wireguard"
  server_type  = var.bastion_server_type
  location     = var.bastion_location
  firewall_ids = [hcloud_firewall.firewall_bastion[0].id]
  ssh_keys     = var.my_ssh_key_names
  depends_on = [
    hcloud_network_subnet.network_subnet
  ]
  user_data = templatefile("${path.module}/cloud-init-bastion.tftpl", {
    server_timezone = var.server_timezone
    server_locale   = var.server_locale
    server_packages = var.server_packages
    cluster_name    = var.cluster_name
    cluster_user    = var.cluster_user
    ssh_port        = var.ssh_port
    public_ssh_keys = var.my_public_ssh_keys
    bastion_ip      = local.bastion_ip
    minion_id       = "bastion"
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

resource "hcloud_server_network" "bastion" {
  count      = local.attach_bastion ? 1 : 0
  server_id  = var.enable_dedicated_bastion ? hcloud_server.bastion[0].id : var.use_dedicated_bastion
  network_id = hcloud_network.network.id
  ip         = local.bastion_ip
}
