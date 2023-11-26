# Terraform Hetzner Cloud K3S

## 🎯 About

Get a cheap HA-ready Kubernetes cluster in less than **5 minutes**, with easy configuration setup through simple Terraform variables, 💯 GitOps compatible !

This opinionated Terraform template will generate a ready-to-go cloud infrastructure through Hetzner Cloud provider, with preinstalled [K3S](https://github.com/k3s-io/k3s), the most popular lightweight Kubernetes distribution.

Additional controllers and workers can be easily added thanks to terraform variables, even after initial setup for **easy upscaling**. Feel free to fork this project in order to adapt for your custom needs.

Check [Kube-Hetzner](https://github.com/kube-hetzner/terraform-hcloud-kube-hetzner) for a more advanced setup with Hetzner Cloud with optimized OS for containers workload. The current project uses only OS supported by Hetzner and intends to be far more lightweight without any local/remote exec provisioners (only cloud-init), quicker to set up, and Windows compatible.

> For people that need a lightweight container orchestrator, the [Swarm provider](https://github.com/okami101/terraform-hcloud-swarm) should be a better fit.

### Networking and firewall

All nodes will be linked with a proper private network as well as **solid firewall protection**. For admin management, only control planes will have open ports for SSH (configurable) and kube-apiserver (port **6443**), with **IP whitelist** support. Other internal nodes can only be accessed by SSH Jump.

Hetzner Load Balancer can be used for any external public access to your cluster as well as your controller pane. Simply set `lb_type` for a specific nodepool in order to create dedicated LB. Then directly use `hcloud_load_balancer_service` for enabling any services (mostly HTTP / HTTPS), allowing high flexibility. Check [kube config](kube.tf.example) for complete example.

### OS management

This Terraform template includes **[Salt Project](https://docs.saltproject.io)** as well for easy global OS management of the cluster through ssh, perfect for upgrades in one single time !

### Dedicated bastion support

By default, the 1st control-pane is used as SSH bastion. Use `enable_dedicated_bastion` variable to enable a dedicated bastion node. Salt master will be installed in the dedicated bastion. It comes with WireGuard VPN preinstalled as well, offering better, and simpler centralized security management instead of using IP whitelist. Once logged into bastion through SSH, use `sudo -s` to configure WireGuard, you must have a valid domain pointing to the bastion public IP in order to generate SSL certificate for WireGuard UI.

## ✅ Requirements

Before starting, you need to have :

1. A Hetzner cloud account.
2. A `terraform` client.
3. A `hcloud` client.
4. A `kubectl` client.

On Windows :

```powershell
scoop install terraform hcloud
```

## 🏁 Starting

### Prepare

The first thing to do is to prepare a new hcloud project :

1. Create a new **EMPTY** hcloud empty project.
2. Generate a **Read/Write API token key** to this new project according to [this official doc](https://docs.hetzner.com/cloud/api/getting-started/generating-api-token/).

### Setup

Now it's time for initial cluster setup.

1. Copy [this kube config example](kube.tf.example) into a new empty directory and rename it `kube.tf`.
2. Execute `terraform init` in order to install the required module
3. Replace all variables according your own needs.
4. Finally, use `terraform apply` to check the plan and initiate the cluster setup.

## Usage

### Access

Once terraform installation is complete, terraform will output the SSH config necessary to connect to your cluster for each node.

Copy the SSH config to your own SSH config, default to `~/.ssh/config`. After few minutes, you can use `ssh <cluster_name>` in order to log in to your main control plane node. For other nodes, the control plane will be used as a bastion for direct access to other nodes, so use `ssh <cluster_name>-worker-01` to directly access to your *worker-01* node.

### Salt

Once logged to your bastion, don't forget to active *Salt*, just type `sudo salt-key -A` in order to accept all discovered minions. You are now ready to use any `salt` commands for global OS management, as `sudo salt '*' pkg.upgrade` for global OS upgrade in one single time.

> If salt-key command is not existing, wait few minutes as it's necessary that cloud-init has finished his job.

### Kubernetes

#### Check K3S status

When logged, use `sudo kubectl get nodes -o wide` to check node status and be sure all nodes is ready and have proper private IPs. Then use `sudo cat /etc/rancher/k3s/k3s.yaml` to get the kubeconfig file and use it with your local kubectl (default to `~/.kube/config`). Adapt the IP accordingly to any valid public controllers IP.

You should now be able to use `kubectl` commands remotely to manage your cluster and ready-to-go to do some deployments !

#### Upscaling and downscaling

You can easily add or remove nodes by changing the `count` variable of each pool or control plane. Then use `terraform apply` to apply the changes.

* When adding, the K3S server or agent will be automatically added to the cluster and ready to use. Don't forget to accept the new minion with `sudo salt-key -A`.
* When removing, you should manually drain and delete node before removing the node with `sudo kubectl drain --ignore-daemonsets <cluster_name>-<pool>-<count>` and `sudo kubectl delete nodes <cluster_name>-<pool>-<count>`. Then use `terraform apply` to delete the node physically.

## Topologies

Contrary to Docker Swarm which is very flexible at low prices, with many topologies possible [as explained here](https://github.com/okami101/terraform-hcloud-swarm#topologies), K8S is really thought out for HA and high horizontal scalability, with complex workloads. So I will only present the typical HA topology for K8S based on following config :

```tf
# ...
control_planes = {
  #...
  count = 3
  taints = [
    "node-role.kubernetes.io/master:NoSchedule"
  ]
}

agent_nodepools = [
  {
    name = "worker"
    #...
    count = 3
    taints = []
    lb_type = "lb11"
  },
  {
    name = "storage"
    #...
    count = 2
    taints = [
      "node-role.kubernetes.io/storage:NoSchedule"
    ],
    volume_size = 20
  }
]
# ...
```

### For administrators

Note as the LB for admin panel (which is not the same as the main frontal LB) is not included in this provider, but can be easily added separately. A round-robin DNS can be used as well.

```mermaid
flowchart TB
ssh((SSH))
kubectl((Kubectl))
kubectl -- Port 6443 --> lb{LB}
ssh -- Port 2222 --> controller-01
lb{LB}
subgraph controller-01
  direction TB
  kube-apiserver-01([Kube API Server])
  etcd-01[(ETCD)]
  kube-apiserver-01 --> etcd-01
end
subgraph controller-02
  direction TB
  kube-apiserver-02([Kube API Server])
  etcd-02[(ETCD)]
  kube-apiserver-02 --> etcd-02
end
subgraph controller-03
  direction TB
  kube-apiserver-03([Kube API Server])
  etcd-03[(ETCD)]
  kube-apiserver-03 --> etcd-03
end
lb -- Port 6443 --> controller-01
lb -- Port 6443 --> controller-02
lb -- Port 6443 --> controller-03
```

### For clients

Next is a typical HA topology, with 3 load-balanced workers, and 2 storage nodes with replicated DB and replicated storage via Longhorn.

```mermaid
flowchart TB
client((Client))
client -- Port 80 + 443 --> lb{LB}
lb{LB}
lb -- Port 80 --> worker-01
lb -- Port 80 --> worker-02
lb -- Port 80 --> worker-03
subgraph worker-01
  direction TB
  traefik-01{Traefik}
  app-01([My App replica 1])
  traefik-01 --> app-01
end
subgraph worker-02
  direction TB
  traefik-02{Traefik}
  app-02([My App replica 2])
  traefik-02 --> app-02
end
subgraph worker-03
  direction TB
  traefik-03{Traefik}
  app-03([My App replica 3])
  traefik-03 --> app-03
end
overlay(Overlay network)
worker-01 --> overlay
worker-02 --> overlay
worker-03 --> overlay
overlay --> db-rw
overlay --> db-ro
db-rw((RW SVC))
db-rw -- Port 5432 --> storage-01
db-ro((RO SVC))
db-ro -- Port 5432 --> storage-01
db-ro -- Port 5432 --> storage-02
subgraph storage-01
  pg-primary([PostgreSQL primary])
  longhorn-01[(Longhorn<br>volume)]
  pg-primary --> longhorn-01
end
subgraph storage-02
  pg-replica([PostgreSQL replica])
  longhorn-02[(Longhorn<br>volume)]
  pg-replica --> longhorn-02
end
db-streaming(Streaming replication)
storage-01 --> db-streaming
storage-02 --> db-streaming
```

## 📝 License

This project is under license from MIT. For more details, see the [LICENSE](https://adr1enbe4udou1n.mit-license.org/) file.

Made with :heart: by <a href="https://github.com/adr1enbe4udou1n" target="_blank">Adrien Beaudouin</a>
