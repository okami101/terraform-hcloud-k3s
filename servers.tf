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
  lifecycle {
    ignore_changes = [
      firewall_ids,
      # user_data,
      ssh_keys,
      image
    ]
  }
  user_data = <<-EOT
#cloud-config
${yamlencode(merge(
  local.base_cloud_init,
  {
    packages = var.server_packages,
    write_files = [
      local.ssh_custom_config,
      local.minion_custom_config,
      local.multipath_custom_config,
      {
        path        = "/etc/rancher/k3s/config.yaml"
        encoding    = "b64"
        permissions = "0644"
        content = base64encode(each.value.role == "controller" ? yamlencode(
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
      },
    ]
    run_cmd = concat(
      local.base_run_cmd,
      each.value.ip == local.first_controller_ip ? [
        "${local.k3s_install} sh -s - server --cluster-init",
        ] : [
        "sleep 30",
        "${local.k3s_install} K3S_URL=https://${local.first_controller_ip}:6443 sh -s - ${each.value.role == "controller" ? "server" : "agent"}",
      ]
    )
  }
))}
EOT
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
