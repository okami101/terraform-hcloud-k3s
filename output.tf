output "network" {
  value       = hcloud_network.network
  description = "Private Hetzner network"
}

output "firewall_private" {
  value       = hcloud_firewall.firewall_private
  description = "Private Hetzner firewall, allowing attaching to any custom servers"
}

output "lbs" {
  value       = hcloud_load_balancer.lbs
  description = "Hetzner load balancers, use them to configure services"
}

output "controllers" {
  value       = [for s in local.servers : hcloud_server.servers[s.name] if s.role == "controller"]
  description = "Controller servers"
}

output "workers" {
  value = { for n in var.agent_nodepools :
    n.name => [for s in local.servers : hcloud_server.servers[s.name] if s.role == n.name]
  }
  description = "Workers grouped by role"
}

output "ssh_config" {
  description = "SSH config to access to the server"
  value = templatefile("${path.module}/ssh.config.tftpl", {
    cluster_name = var.cluster_name
    cluster_user = var.cluster_user
    ssh_port     = var.ssh_port
    bastion_ip   = local.bastion_ip
    servers      = local.servers
  })
}
