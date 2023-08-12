output "network_id" {
  value       = hcloud_network.network.id
  description = "ID of the private network"
}

output "bastion_ip" {
  value       = local.bastion_ip
  description = "Public ip address of the bastion, link this IP to connection to your bastion server"
}

output "controller_ips" {
  value       = [for s in local.servers : hcloud_server.servers[s.name].ipv4_address if s.role == "controller"]
  description = "Public ip address of the controllers"
}

output "controller_ids" {
  value       = [for s in local.servers : hcloud_server.servers[s.name].id if s.role == "controller"]
  description = "Hetzner Identifier of controller servers"
}

output "worker_ids" {
  value = { for n in var.agent_nodepools :
    n.name => [for s in local.servers : hcloud_server.servers[s.name].id if s.role == n.name]
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
