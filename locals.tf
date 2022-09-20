locals {
  servers = flatten([
    [
      for i in range(var.controllers.server_count) : {
        name              = "controller-${format("%02d", i + 1)}"
        server_type       = var.controllers.server_type
        role              = "controller"
        ip                = "10.0.0.${i + 2}"
        private_interface = var.controllers.private_interface
      }
    ],
    flatten([
      for i, s in var.workers : [
        for j in range(s.server_count) : {
          name              = "${s.role}-${format("%02d", j + 1)}"
          server_type       = s.server_type
          role              = s.role
          ip                = "10.0.${i + 1}.${j + 1}"
          private_interface = s.private_interface
        }
      ]
    ])
  ])
  bastion_server_name = "controller-01"
  bastion_server      = one([for s in local.servers : s if s.name == local.bastion_server_name])
  controllers         = tolist([for s in local.servers : s if s.role == "controller"])
  main_workers        = tolist([for s in local.servers : s if s.role == "worker"])
}
