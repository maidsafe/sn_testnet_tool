# Safe Network Testnet Tool

We support creating testnets on either AWS or Digital Ocean.

This tool can be used to automate their creation.

# Testnets on AWS

A testnet can be launched on AWS, where each node will run on an EC2 instance in a VPC.

The VPC and other infrastructure should have been setup in advance, using our [testnet-infra repo](https://github.com/maidsafe/terraform-testnet-infra). This process will use a basic Terraform configuration to launch the EC2 instances on the VPC, then use Ansible to provision them with the node setup.

## Setup

The process for spinning up a testnet requires the use of quite a few tools, so for this reason, we've provided a container from which the process can run.

So the first step is to get an installation of [Docker](https://www.docker.com/). There is a good chance it will be available in the package manager for your platform.

After your Docker setup is running, build the container by issuing `docker build --tag sn_testnet_tool:latest .` from this directory. It may take a few minutes to build.

Obtain the AWS access and secret access keys for the `testnet_runner` account, and also the password for the Ansible vault. Put the Ansible password in a file located at `~/.ansible/vault-password`.

Now create a .env at the same level where this directory is, and fill it with the following, replacing each value as appropriate:
```
AWS_ACCESS_KEY_ID=<value>
AWS_SECRET_ACCESS_KEY=<value>
AWS_DEFAULT_REGION=eu-west-2
DIGITALOCEAN_TOKEN=<value>
DO_API_TOKEN=<value>
SSH_KEY_NAME=id_rsa
SN_TESTNET_DEV_SUBNET_ID=subnet-018f2ab26755df7f9
SN_TESTNET_DEV_SECURITY_GROUP_ID=sg-0d47df5b3f0d01e2a
TERRAFORM_STATE_BUCKET_NAME=maidsafe-org-infra-tfstate
```

The EC2 instances need to be launched with an SSH key pair and Ansible will also use the same key for its SSH access. You can either generate a new key pair or use an existing one. In either case, set `SSH_KEY_NAME` to the name of a key pair in your `~/.ssh` directory. It should have both private and public key files. So for example, if you set it to `id_rsa`, we expect there will be two files, `~/.ssh/id_rsa` and `~/.ssh/id_rsa.pub`. The `.pub` extension is necessary.

## Create a Testnet

Launch the runner container and navigate to the `sn_testnet_tool` directory:
```
./runner.sh
runner@538cec9f8bdf:~$ cd sn_testnet_tool
runner@538cec9f8bdf:~/sn_testnet_tool$
```

The `runner.sh` script wraps all the tedious arguments required to launch the container. You will then find yourself at a Bash prompt inside the container, similar to the one above.

From here, you can create a testnet like so:
```
runner@538cec9f8bdf:~/sn_testnet_tool$ just init "beta" "digital-ocean"
```

Here "beta" is the name of the testnet. The name should be a short word, e.g., "alpha" or "beta", or your first name (though the name "dev" cannot be used, because that's the main workspace that cannot be deleted). This will create a Terraform workspace, a key pair on EC2, and Ansible inventory files.

Now create the testnet:
```
runner@538cec9f8bdf:~/sn_testnet_tool$ just testnet "beta" "digital-ocean" 10
```

Terraform will run to create the instances then Ansible will be used to provision them.

You can do the same on AWS by replacing "digital-ocean" with "aws".

## Working with a Testnet

On each EC2 instance or droplet, the node is running as a service, as the `safe` user.

There are various utility targets that can be called:

* `just ssh-details "beta" "digital-ocean"`: will print out a list of all the nodes and their public IP addresses, which you can then use to SSH to any node.
* `just logs "beta" "digital-ocean"`: will get the logs from all the machines in the testnet and make them available in a `logs` directory locally.

The node runs as a service, so it's possible to SSH to the instance and view its logs using `journalctl`:
```
journalctl -u safenode # print the log with paging
journalctl -f -u safenode # follow the log while it's updating
journalctl -u safenode -o cat --no-pager # print the whole log without paging
```

This can be useful for quick debugging.

## Teardown

When you're finished with the testnet, run `just clean <name>`. This will destroy the EC2 instances, delete the Terraform workspace, remove the key pair on EC2 and delete the Ansible inventory files.

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
