output "servers" {
  value       = local.servers
  description = "List of servers"
}

output "bastion_ip" {
  value       = hcloud_server.servers[local.bastion_server_name].ipv4_address
  description = "Public ip address of the bastion, link this IP to connection to your bastion server"
}

output "controller_ips" {
  value       = [for s in local.servers : hcloud_server.servers[s.name].ipv4_address if s.role == "controller"]
  description = "Public ip address of the controllers"
}

output "lb_ip" {
  value       = hcloud_load_balancer.lb.ipv4
  description = "Public ip address of the load balancer, use this IP as main HTTPS entrypoint through your worker nodes"
}

output "ssh_config" {
  description = "SSH config to access to the server"
  value = templatefile("ssh.config.tftpl", {
    cluster_name = var.cluster_name
    cluster_user = var.cluster_user
    bastion_ip   = hcloud_server.servers[local.bastion_server_name].ipv4_address
    servers      = local.servers
  })
}
