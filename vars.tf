variable "server_image" {
  description = "The default OS image to use for the servers"
  type        = string
  default     = "ubuntu-22.04"
}

variable "server_location" {
  description = "The default location where to create hcloud resources"
  type        = string
  default     = "nbg1"
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

variable "my_public_ssh_key" {
  description = "Your public SSH key that will be used to access the servers"
  type        = string
  sensitive   = true
}

variable "my_ip_addresses" {
  description = "Your public IP addresses for port whitelist via the Hetzner firewall configuration"
  type        = list(string)
  default = [
    "0.0.0.0/0",
    "::/0"
  ]
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

variable "disabled_components" {
  description = "Components to disable for k3s installation"
  type        = list(string)
  default     = []
}

variable "control_planes" {
  description = "Size and count of control planes"
  type = object({
    server_type       = string,
    private_interface = string
    count             = string,
    labels            = list(string)
    taints            = list(string)
  })
}

variable "agent_nodepools" {
  description = "List of all additional worker types to create for k3s cluster. Each type is identified by specific role and can have a different number of instances. The k3sctl config will be updated as well. If the role is different from 'worker', this node will be tainted for preventing any scheduling from pods without proper tolerations."
  type = list(object({
    name              = string
    server_type       = string
    private_interface = string
    private_ip_index  = optional(number)
    count             = number
    taints            = list(string)
    volume_size       = optional(number)
  }))
}

variable "lb_type" {
  description = "Server type of load balancer"
  type        = string
}

variable "lb_target" {
  description = "Nodepool to be load balanced"
  type        = string
}
