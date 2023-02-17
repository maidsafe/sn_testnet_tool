variable "ami_id" {
  default = "ami-01b8d743224353ffe"
  description = "AMI ID for Ubuntu 22.04"
}

variable "instance_type" {
  default = "t2.small"
  description = "Type of the EC2 instances for the nodes"
}

variable "key_pair_name" {
  description = "Name of the key pair with which to launch the EC2 instances for the nodes"
}

variable "vpc_subnet_id" {
  description = "ID of the subnet in which to launch the EC2 instances for the nodes"
}

variable "vpc_security_group_id" {
  description = "ID of the security group in which to launch the EC2 instances for the nodes"
}

variable "node_count" {
  default = 30
  description = "The number of EC2 instances to launch for the nodes"
}

variable "enable_client" {
  type = bool
  default = false
  description = "Controls provisioning for a machine for running client tests"
}

variable "client_instance_type" {
  default = "c5.9xlarge"
  description = "Type of the client instance (typically bigger than a node machine)"
}

variable "client_ami_id" {
  default = "ami-00632730219704074"
  description = "Client AMI ID which is the same as the build agent"
}
