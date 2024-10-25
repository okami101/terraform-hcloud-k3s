locals {
  first_controller_ip   = "10.${var.network_index}.0.2"
  first_controller_name = "controller-01"
  attach_bastion        = var.enable_dedicated_bastion || var.use_dedicated_bastion != null
  bastion_ip            = local.attach_bastion ? "10.${var.network_index}.100.1" : local.first_controller_ip
  servers = concat(
    [
      for i in range(var.control_planes.count) : {
        name              = "controller-${format("%02d", i + 1)}"
        server_type       = var.control_planes.server_type
        location          = var.control_planes.location
        private_interface = var.control_planes.private_interface
        ip                = "10.${var.network_index}.0.${i + 2}"
        role              = "controller"
        labels            = var.control_planes.labels
        taints            = var.control_planes.taints
        lb_type           = var.control_planes.lb_type
        volume_size       = 0
      }
    ],
    flatten([
      for i, s in var.agent_nodepools : [
        for j in range(s.count) : {
          name              = "${s.name}-${format("%02d", j + 1)}"
          server_type       = s.server_type
          location          = s.location
          private_interface = s.private_interface
          ip                = "10.${var.network_index}.${coalesce(s.private_ip_index, i) + 1}.${j + 1}"
          role              = s.name
          labels            = s.labels
          taints            = s.taints
          lb_type           = s.lb_type
          volume_size       = s.volume_size != null ? s.volume_size : 0
          volume_format     = s.volume_format != null ? s.volume_format : "ext4"
        }
      ]
    ])
  )
  subnets = concat(
    [
      {
        name = "control_plane"
        ip   = "10.${var.network_index}.0.0/24"
      }
    ],
    [
      for i, s in var.agent_nodepools : {
        name = s.name
        ip   = "10.${var.network_index}.${coalesce(s.private_ip_index, i) + 1}.0/24"
      }
    ],
    local.attach_bastion ? [
      {
        name = "bastion"
        ip   = "10.${var.network_index}.100.0/24"
      }
    ] : [],
  )
  load_balancers = concat(
    var.control_planes.lb_type != null ? [{
      name     = "controller"
      type     = var.control_planes.lb_type
      location = var.control_planes.location
      ip       = "10.${var.network_index}.0.100"
    }] : [],
    [
      for i, s in var.agent_nodepools : {
        name     = s.name
        type     = s.lb_type
        location = s.location
        ip       = "10.${var.network_index}.${coalesce(s.private_ip_index, i) + 1}.100"
      } if s.lb_type != null
    ]
  )
  base_cloud_init = {
    locale                     = var.server_locale
    timezone                   = var.server_timezone
    package_reboot_if_required = true
    package_update             = true
    package_upgrade            = true
    users = [
      {
        groups = [
          "adm",
          "sudo",
        ]
        name  = var.cluster_user
        shell = "/bin/bash"
        sudo  = "ALL=(ALL) NOPASSWD:ALL"
        uid   = 1000
      },
    ]
  }
  ssh_custom_config = {
    content     = <<-EOT
Port 2222
PermitRootLogin no
PasswordAuthentication no
      EOT
    path        = "/etc/ssh/sshd_config.d/99-custom.conf"
    permissions = "0644"
  }
  minion_custom_config = {
    content     = <<-EOT
master: ${local.bastion_ip}
EOT
    path        = "/etc/salt/minion.d/99-custom.conf"
    permissions = "0644"
  }
  multipath_custom_config = {
    content     = <<-EOT
defaults {
  user_friendly_names yes
}
blacklist {
    devnode "^sd[a-z0-9]+"
}
EOT
    path        = "/etc/multipath.conf"
    permissions = "0644"
  }
  base_run_cmd = [
    "mkdir -p /home/${var.cluster_user}/.ssh",
    "cp /root/.ssh/authorized_keys /home/${var.cluster_user}/.ssh/",
    "chown -R ${var.cluster_user}:${var.cluster_user} /home/${var.cluster_user}/.ssh",
    "chmod 700 /home/${var.cluster_user}/.ssh",
    "chmod 600 /home/${var.cluster_user}/.ssh/authorized_keys",
    "systemctl restart ssh",
    "curl -L https://bootstrap.saltproject.io | sudo sh -s --"
  ]
  k3s_install = "curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=${var.k3s_channel} K3S_TOKEN=${random_password.k3s_token.result}"
}
