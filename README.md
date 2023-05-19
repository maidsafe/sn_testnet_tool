# Safe Network Testnet Tool

We support creating testnets on either AWS or Digital Ocean.

This tool can be used to automate their creation.

## Testnets on AWS

A testnet can be launched on AWS, where each node will run on an EC2 instance in a VPC.

The VPC and other infrastructure should have been setup in advance, using our [testnet-infra repo](https://github.com/maidsafe/terraform-testnet-infra). This process will use a basic Terraform configuration to launch the EC2 instances on the VPC, then use Ansible to provision them with the node setup.

## Setup

The process for spinning up a testnet requires the use of quite a few tools, so for this reason, we've provided a container from which the process can run. However, if preferred, rather than use the container, it's also possible to setup the tools directly on the host. You can inspect the `Dockerfile` to see which tools are required. Most of the instructions in this document will be oriented to the container setup.

The first step is to get an installation of [Docker](https://www.docker.com/). There's a good chance it will be available in the package manager for your platform.

After your Docker setup is running, you can build the container using the `build-container.sh` script from this directory. It may take five minutes or so to build.

Obtain the AWS access and secret access keys for the `testnet_runner` account, and also the password for the Ansible vault. Put the Ansible password in a file located at `~/.ansible/vault-password`.

Now create a .env at the same level where this directory is, and fill it with the following, replacing each value as appropriate:
```
AWS_ACCESS_KEY_ID=<value>
AWS_SECRET_ACCESS_KEY=<value>
AWS_DEFAULT_REGION=eu-west-2
DO_PAT=<value>
SSH_KEY_NAME=id_rsa
SN_TESTNET_DEV_SUBNET_ID=subnet-018f2ab26755df7f9
SN_TESTNET_DEV_SECURITY_GROUP_ID=sg-0d47df5b3f0d01e2a
TERRAFORM_STATE_BUCKET_NAME=maidsafe-org-infra-tfstate
```

The EC2 instances need to be launched with an SSH key pair and Ansible will also use the same key for its SSH access. You can either generate a new key pair or use an existing one. In either case, set `SSH_KEY_NAME` to the name of a key pair in your `~/.ssh` directory. It should have both private and public key files. So for example, if you set it to `id_rsa`, we expect there will be two files, `~/.ssh/id_rsa` and `~/.ssh/id_rsa.pub`. The `.pub` extension is necessary.

## Create a Testnet

The container requires a lot of arguments to run properly, so there are some utility scripts to wrap its use.

To create a testnet on AWS, you can use:
```
./up.sh "<name>" "aws" 10
```

The `name` should be a short, lowercase value without any spaces. Examples would be your first name, or something like "alpha" or "beta". The name "dev" is reserved for administration purposes.

Terraform will run to create the instances, then Ansible will be used to provision them.

A custom, locally built `safenode` binary can be supplied by using an additional argument:
```
./up.sh "<name>" "aws" 10 "<path>"
```

We can use Digital Ocean by replacing "aws" with "digital-ocean".

## Working with a Testnet

On each EC2 instance or droplet, the node is running as a service, as the `safe` user.

There are various utility targets that can be called:

* `./run.sh just ssh-details "beta" "digital-ocean"`: will print out a list of all the nodes and their public IP addresses, which you can then use to SSH to any node.
* `./run.sh just logs "beta" "digital-ocean"`: will get the logs from all the machines in the testnet and make them available in a `logs` directory locally.

The node runs as a service, so it's possible to SSH to the instance and view its logs using `journalctl`:
```
journalctl -u safenode # print the log with paging
journalctl -f -u safenode # follow the log while it's updating
journalctl -u safenode -o cat --no-pager # print the whole log without paging
```

This can be useful for quick debugging.

## Teardown

When you're finished with the testnet, run `./down.sh "beta" "aws"`. This will destroy the EC2 instances, delete the Terraform workspace, remove the key pair on EC2 and delete the Ansible inventory files.

## Development

This section provides information and guidelines on making contributions.

The automation is implemented using these tools:

* A Justfile with targets written in Bash
* Terraform
* Ansible

Terraform is used to create the infrastructure and Ansible is used to provision it. Terraform has some basic provisioning capability, but it's clunky to use; we therefore opt for Ansible for provisioning, since it was designed for that purpose.

The `Justfile` targets coordinate the use of both the tools.

### Terraform

The Terraform setup is really simple. We use two different modules: one for AWS and one for Digital Ocean. The modules follow the [standard module structure](https://cloud.google.com/docs/terraform/best-practices-for-terraform#module-structure), with a `main.tf` and a `variables.tf`.

We define the EC2 instances/droplets in `main.tf` and things like the sizes of VMs in `variables.tf`. For AWS, the EC2 instances are intended to be deployed to an existing VPC. For that reason, we need to provide a subnet ID and a security group ID. This infrastructure is defined elsewhere, because in this repository we only want to deal with the creation of a testnet.

### Ansible

To provide an extremely brief introduction to Ansible, it is a mature tool whose purpose is to provision and manage groups of servers. It uses an SSH connection to apply what it calls a 'playbook' to a list of hosts. A playbook is a list of tasks or roles, where a role is also just a list of tasks. Roles are somewhat analogous to classes in object oriented programming: they can be defined once and re-used in multiple playbooks. Tasks are things like installing packages, creating directories, copying files and so on. They are implemented as Python modules. Playbooks, roles and tasks are defined in YAML. The servers that playbooks are applied to are provided using inventory. The inventory can be a static list of IPs/DNS names, or it can be generated dynamically by examining things like the tags applied to the EC2 instaces or droplets.

In our case, we have two main playbooks: one for the genesis node and the other for the remaining nodes. They are almost identical, but differ in that the genesis and remaining nodes need slightly different setups. Both playbooks use the `node` role, which uses a Jinja template to define a service definition for running `safenode`.

There are some other utility playbooks for things like retrieving logs from the servers.
