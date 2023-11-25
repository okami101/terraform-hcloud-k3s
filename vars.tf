variable "server_image" {
  description = "The default OS image to use for the servers"
  type        = string
  default     = "ubuntu-22.04"
}

variable "network_zone" {
  description = "The network zone where to attach hcloud resources"
  type        = string
  default     = "eu-central"
}

variable "server_timezone" {
  description = "The default timezone to use for the servers"
  type        = string
  default     = null
}

variable "server_locale" {
  description = "The default locale to use for the servers"
  type        = string
  default     = null
}

variable "server_packages" {
  description = "Default packages to install on cloud init"
  type        = list(string)
  default     = []
}

variable "ssh_port" {
  description = "Default SSH port to use for node access"
  type        = number
  default     = null
}

variable "cluster_name" {
  description = "Used as hostname prefix for all hcloud resources"
  type        = string
  default     = "k3s"
}

variable "cluster_user" {
  description = "The default non-root user (UID=1000) that will be used for accessing all nodes"
  type        = string
  default     = "kube"
}

variable "my_ssh_key_names" {
  description = "List of hcloud SSH key names that will be used to access the servers"
  default     = []
  type        = list(string)
}

variable "my_public_ssh_keys" {
  description = "Your public SSH keys that will be used to access the servers"
  type        = list(string)
  sensitive   = true
}

variable "my_ip_addresses" {
  description = "Your public IP addresses for port whitelist via the Hetzner firewall configuration"
  type        = list(string)
  sensitive   = true
  default = [
    "0.0.0.0/0",
    "::/0"
  ]
}

variable "allowed_inbound_ports" {
  description = "Ports whitelist for workers via the Hetzner firewall configuration"
  type        = list(number)
  default     = []
}

variable "k3s_channel" {
  description = "K3S channel to use for the installation"
  type        = string
  default     = "stable"
}

variable "tls_sans" {
  description = "Additional TLS SANs to use for the k3s installation"
  type        = list(string)
  default     = []
}

variable "kubelet_args" {
  description = "Additional arguments for each kubelet service"
  type        = list(string)
  default     = []
}

variable "etcd_s3_backup" {
  description = "S3 backup configuration for etcd"
  type        = map(any)
  sensitive   = true
  default     = {}
}

variable "control_planes_custom_config" {
  type        = any
  default     = {}
  description = "Custom control plane configuration e.g to allow etcd monitoring."
}

variable "disable_flannel" {
  description = "Disable flannel for k3s installation"
  type        = bool
  default     = false
}

variable "enable_wireguard" {
  description = "Enable wireguard for flannel backend"
  type        = bool
  default     = false
}

variable "disabled_components" {
  description = "Components to disable for k3s installation"
  type        = list(string)
  default     = []
}

variable "enable_bastion" {
  description = "Install a bastion host with wireguard VPN for accessing the cluster"
  type        = bool
  default     = false
}

variable "bastion_server_type" {
  description = "Hetzner server type of bastion"
  type        = string
  default     = "cx11"
}

variable "bastion_location" {
  description = "Hetzner server type of bastion"
  type        = string
  default     = "nbg1"
}

variable "wireguard_ui_port" {
  description = "Wireguard UI port"
  type        = string
  default     = "443"
}

variable "control_planes" {
  description = "Size and count of control planes"
  type = object({
    server_type       = string
    location          = string
    private_interface = string
    count             = string
    labels            = list(string)
    taints            = list(string)
    lb_type           = optional(string)
  })
}

variable "agent_nodepools" {
  description = "List of all additional worker types to create for k3s cluster. Each type is identified by specific role and can have a different number of instances. The k3sctl config will be updated as well. If the role is different from 'worker', this node will be tainted for preventing any scheduling from pods without proper tolerations."
  type = list(object({
    name              = string
    server_type       = string
    location          = string
    private_interface = string
    private_ip_index  = optional(number)
    count             = number
    labels            = list(string)
    taints            = list(string)
    lb_type           = optional(string)
    volume_size       = optional(number)
    volume_format     = optional(string)
  }))
}
