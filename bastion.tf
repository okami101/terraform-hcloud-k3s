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
  lifecycle {
    ignore_changes = [
      firewall_ids,
      user_data,
      ssh_keys,
      image
    ]
  }
  user_data = <<-EOT
#cloud-config
${yamlencode(merge(
  local.base_cloud_init,
  {
    write_files = [
      local.ssh_custom_config,
      local.minion_custom_config,
    ]
    runcmd = [
      "${local.salt_bootstrap_script} | sh -s -- -M"
    ]
  }
))}
EOT
}

resource "hcloud_server_network" "bastion" {
  count      = local.attach_bastion ? 1 : 0
  server_id  = var.enable_dedicated_bastion ? hcloud_server.bastion[0].id : var.use_dedicated_bastion
  network_id = hcloud_network.network.id
  ip         = local.bastion_ip
}
