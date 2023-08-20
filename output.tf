output "network_id" {
  value       = hcloud_network.network.id
  description = "ID of the private network"
}

output "firewall_private_id" {
  value       = hcloud_firewall.firewall_private.id
  description = "ID of the private firewall, allowing attaching to any custom servers"
}

output "lbs" {
  value       = hcloud_load_balancer.lbs
  description = "Hetzner load balancers, use them to configure services"
}

output "controllers" {
  value       = [for s in local.servers : hcloud_server.servers[s.name] if s.role == "controller"]
  description = "Hetzner Identifier of controller servers"
}

output "workers" {
  value = { for n in var.agent_nodepools :
    n.name => [for s in local.servers : hcloud_server.servers[s.name] if s.role == n.name]
  }
  description = "Hetzner Identifier of workers grouped by role"
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
