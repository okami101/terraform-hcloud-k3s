locals {
  servers = flatten([
    [
      for i in range(var.control_planes.count) : {
        name              = "controller-${format("%02d", i + 1)}"
        server_type       = var.control_planes.server_type
        private_interface = var.control_planes.private_interface
        ip                = "10.0.0.${i + 2}"
        role              = "controller"
        taints            = var.control_planes.taints
      }
    ],
    flatten([
      for i, s in var.agent_nodepools : [
        for j in range(s.count) : {
          name              = "${s.name}-${format("%02d", j + 1)}"
          server_type       = s.server_type
          private_interface = s.private_interface
          ip                = "10.0.${coalesce(s.private_ip_index, i) + 1}.${j + 1}"
          role              = s.name
          taints            = s.taints
        }
      ]
    ])
  ])
  bastion_server_name = "controller-01"
  bastion_server      = one([for s in local.servers : s if s.name == local.bastion_server_name])
  bastion_ip          = hcloud_server.servers[local.bastion_server_name].ipv4_address
}
