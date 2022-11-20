# Terraform Hetzner Cloud K3S

## :dart: About

Get a powerful HA-ready Kubernetes cluster in less than **5 minutes** for less than **$30/month**, with easy configuration setup through simple Terraform variables, 💯 GitOps compatible !

This Terraform template will generate a ready-to-go cloud infrastructure through Hetzner Cloud provider, with preinstalled [K3S](https://github.com/k3s-io/k3s), the most popular lightweight Kubernetes distribution. By default, when using [this example file](terraform.tfvars.example) without any changes except required variables, the cluster will be created with following resources :

1. **1 main control pane** server as Kubernetes controller
2. **2 worker nodes**
3. **1 load balancer** for HA with above workers as targets, balancing 80 and 443 TCP port (L4 protocol)
4. **1 data node** tainted for any Data/DB specific tasks
5. **1 10GB volume** mounted on data node

All nodes use **CX21** server type by default (configurable, cf below for advanced configuration).
Total price of this default setup : 6.42 \* 4 + 6.47 + 0.53 \* 1 = **$32,68** / month.

Additional controllers and workers can be easily added thanks to terraform variables, even after initial setup for **easy upscaling**, enabling complete **GitOps infrastructure management**. Feel free to fork this project in order to adapt for your custom needs.

Check [Kube-Hetzner](https://github.com/kube-hetzner/terraform-hcloud-kube-hetzner) for a more advanced setup with Hetzner Cloud with optimized OS for containers workload. This project intends to be far more lightweight without any local/remote exec provisioners, only cloud-init, so far less hacky and quicker to setup.

### Networking and firewall

All nodes including LB will be linked with a proper private network as well as **solid firewall protection**. Only the 1st main control pane node will have open ports for SSH (port **2222**) and kube-apiserver (port **6443**) for admin management. Other internal nodes will be accessed by SSH Jump. **IP whitelist** is supported by simple TF variable.

### OS management

This Terraform template includes **[Salt Project](https://docs.saltproject.io)** as well for easy global OS management of the cluster through ssh, perfect for upgrades in one single time ! The NFS client is also installed by default for any usage through remote NFS server for stateful workloads.

## :white_check_mark: Requirements

Before starting, you need to have :

1. A Hetzner cloud account.
2. A `terraform` client. On Windows, this is a simple `scoop install terraform`.
3. Optionally access to a DNS on any registrar is recommended.

Before continue, **DO NOT** reuse any existing hcloud project as we'll use terraform !

## :checkered_flag: Starting

### Prepare

The first thing to do is to prepare a new hcloud project :

1. Create a new **EMPTY** hcloud empty project.
2. Generate a **Read/Write API token key** to this new project according to [this official doc](https://docs.hetzner.com/cloud/api/getting-started/generating-api-token/).

Then create your own repo from this template and clone it locally.

### Setup

Now it's time for initial cluster setup :

```bash
# copy default exemple variables
cp terraform.tfvars.example terraform.tfvars
```

Next fill required variables :

| Name              | Default      | Description                                                          |
| ----------------- | ------------ | -------------------------------------------------------------------- |
| hcloud_token      |              | The above token generated from hcloud project                        |
| server_image      | ubuntu-22.04 | Bare OS server of nodes                                              |
| server_type       | nbg1         | Cluster location                                                     |
| server_timezone   |              | Optional timezone for OS                                             |
| server_locale     |              | Optional locale for OS                                               |
| cluster_name      | kube         | Name of the cluster, must be simple alphanum + hyphen + underscore   |
| cluster_user      | kube         | Default UID 1000 sudoer user                                         |
| my_public_ssh_key |              | Your own public ssh key in order to login to any node of the cluster |
| my_ip_addresses   | any          | IP whitelist for Hetzner firewall for SSH and Kube API server        |

You can stay with the default configs for other variables, but don't worry, as we're using Terraform it can be changed easily after cluster installation ❤️

Go to the [main variables](vars.tf) file for all available variables.

### Installation

Finally, you're ready to initiate installation by only few terraform standard steps :

```bash
# check plan
terraform plan

# apply plan
terraform apply
```

## Usage

### Access

Once terraform installation is complete, terraform will output the SSH config necessary to connect to your cluster for each node as well as following public IPs :

| Variable         | Description                                                                       |
| ---------------- | --------------------------------------------------------------------------------- |
| `bastion_ip`     | Bastion IP for server management and Kubernetes installation through SSH          |
| `controller_ips` | All available IPs controllers for Kubernetes API access                           |
| `lb_ip`          | Load Balancer IP to use for your web services accessible through 80 and 443 ports |

Copy the SSH config to your own SSH config, default to `~/.ssh/config`. Then use `ssh <cluster_name>` in order to log in to your main control pane node. For other nodes, the control pane node will be used as a bastion for direct access to other nodes, so you can use for example `ssh <cluster_name>-worker-01` to directly access to your *worker-01* node.

### Salt

Once logged to your bastion, don't forget to active *Salt*, just type `sudo salt-key -A` in order to accept all minions. You are now ready for using `sudo salt '*' pkg.upgrade` from main control pane in order to upgrade all nodes in one single time.

> If salt-key command is not existing, wait few minutes as it's necessary that cloud-init has finished his job.

### Kubernetes

#### Check K3S status

When logged, use `sudo kubectl get nodes -o wide` to check node status and be sure all nodes is ready and have proper private IPs. Then use `cat /etc/rancher/k3s/k3s.yaml` to get the kubeconfig file and use it with your local kubectl (default to `~/.kube/config`). Adapt the IP accordingly to any valid public controllers IP.

> I highly encourage you to use <https://github.com/shanoor/kubectl-aliases-powershell> (bash) or <https://github.com/ahmetb/kubectl-aliases> (PS) for better CLI experience.

## Cluster configuration

This template support many cluster typologies thanks to cluster related variables.

### Bastion Server

The `bastion_server` variable allows you to define the server used for main SSH access. It's `controller-01` by default.

### Kube controllers

Create a HA Kube controller is as easy as edit `controllers` variable :

| Property     | Description                                                                                         |
| ------------ | --------------------------------------------------------------------------------------------------- |
| server_type  | Compute size of servers ([cf available Hetzner sizes](https://www.hetzner.com/cloud#pricing))       |
| server_count | Number of controller instances, 3 at least for HA, should be an odd number for quorum (3,5,7, etc.) |

### Kube workers

Use `workers` variable for workers configuration. It's a list of type of workers, as we can imagine different application types (any DB or GPU dedicated tasks for example).

| Property     | Description                                                                        |
| ------------ | ---------------------------------------------------------------------------------- |
| role         | Worker's role, mostly named as a dedicated task (data, gpu, monitor, runner, etc.) |
| server_type  | Same as controller                                                                 |
| server_count | Number of worker instances for above role                                          |

Note that there is a specific default `worker` role that involve :

1. Will be the only taken into account for load balancing, as others should be use mainly for specific tasks.
2. The dedicated tasks nodes (those different from `worker` role) will be tainted for preventing any scheduling from pods without proper toleration.

### Volumes

| Property | Description                                                                              |
| -------- | ---------------------------------------------------------------------------------------- |
| name     | Hetzner volume identifier name                                                           |
| server   | Server where the volume will be automatically mounted, must correspond to a valid worker |
| size     | Size of volume (from 10GB to 10TB)                                                       |

### Load balancer

Use `lb_services` to specify which services (TCP ports) must be load balanced, mostly `80` and `443` (default). You can also use `lb_worker_role` to specify which role must be load balanced, by default it's `worker` role.

Note as `443` port will use [proxy protocol](https://www.haproxy.org/download/1.8/doc/proxy-protocol.txt) in order to keep user source information when traffic arrive to our workers (client IP). So be sure that your ingress controller (nginx, traefik, etc.) is configured for accepting this protocol.

### Config example

The below config will create following Kubernetes cluster typology :

* **3 controllers**
* **3 default workers** that will be used as targets for load balancing
* **2 data workers** tainted as `data` for data specific tasks (DB, Elasticsearch, ...)
* **2 runner workers** tainted as `runner` for any CI building tasks with powerful AMD CPU
* **2 monitoring workers** tainted as `monitor` for any monitoring tasks (Prometheus and scrapers, etc.)
* **2 volumes**, 1 for each above `data` servers
* **3 load balanced TCP ports** to default workers (with role `worker`) (`22` is useful for any self-hosted VCS service like GitLab, Gitea)

```tf
controllers = {
  server_type       = "cx21"
  server_count      = 3
  private_interface = "ens10"
}
workers = [
  {
    role              = "worker"
    server_type       = "cx21"
    server_count      = 3
    private_interface = "ens10"
  },
  {
    role              = "data",
    server_type       = "cx31"
    server_count      = 2
    private_interface = "ens10"
  },
  {
    role              = "runner"
    server_type       = "cpx31"
    server_count      = 2
    private_interface = "ens10"
  },
  {
    role              = "monitor"
    server_type       = "cx31"
    server_count      = 2
    private_interface = "ens10"
  }
]
volumes = [
  {
    name   = "vol-01"
    server = "data-01"
    size   = 10
  },
  {
    name   = "vol-02"
    server = "data-02"
    size   = 10
  }
]
lb_services = [22, 80, 443]
```

## :memo: License

This project is under license from MIT. For more details, see the [LICENSE](https://adr1enbe4udou1n.mit-license.org/) file.

Made with :heart: by <a href="https://github.com/adr1enbe4udou1n" target="_blank">Adrien Beaudouin</a>
