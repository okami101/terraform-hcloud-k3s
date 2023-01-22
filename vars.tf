variable "server_image" {
  type        = string
  default     = "ubuntu-22.04"
  description = "The default OS image to use for the servers"
}

variable "server_location" {
  type        = string
  default     = "nbg1"
  description = "The default location where to create hcloud resources"
}

variable "server_timezone" {
  type        = string
  default     = null
  description = "The default timezone to use for the servers"
}

variable "server_locale" {
  type        = string
  default     = null
  description = "The default locale to create hcloud servers"
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
  type        = string
  default     = "kube"
  description = "Will be used to create the hcloud servers as a hostname prefix and main cluster name for the k3s cluster"
}

variable "cluster_user" {
  type        = string
  default     = "kube"
  description = "The default non-root user (UID=1000) that will be used to access the servers"
}

variable "my_public_ssh_name" {
  type        = string
  default     = "kube"
  description = "Your public SSH key identifier for the Hetzner Cloud API"
}

variable "my_public_ssh_key" {
  type        = string
  sensitive   = true
  description = "Your public SSH key that will be used to access the servers"
}

variable "my_ip_addresses" {
  type = list(string)
  default = [
    "0.0.0.0/0",
    "::/0"
  ]
  description = "Your public IP addresses for port whitelist via the Hetzner firewall configuration"
}

variable "k3s_channel" {
  type        = string
  default     = "latest"
  description = "K3S channel to use for the installation"
}

variable "controllers" {
  type = object({
    server_type       = string,
    server_count      = string,
    private_interface = string
  })
  description = "Size and count of controller servers"
}

variable "workers" {
  type = list(object({
    role              = string
    server_type       = string
    server_count      = number
    private_interface = string
  }))
  description = "List of all additional worker types to create for k3s cluster. Each type is identified by specific role and can have a different number of instances. The k3sctl config will be updated as well. If the role is different from 'worker', this node will be tainted for preventing any scheduling from pods without proper tolerations."
}

variable "lb_services" {
  type        = list(number)
  description = "List of tcp ports to be load balanced through workers"
}

variable "lb_worker_role" {
  type        = string
  default     = "worker"
  description = "Server role to be load balanced"
}

variable "kubelet_args" {
  type = list(object({
    key   = string,
    value = string
  }))
  description = "Additional arguments for kubelet service"
}
