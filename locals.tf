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
}
