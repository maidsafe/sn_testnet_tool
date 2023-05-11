terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  backend "s3" {
    key    = "sn-testnet-tool-aws.tfstate"
  }
}

module "genesis_ec2_instance" {
  source                 = "terraform-aws-modules/ec2-instance/aws"
  version                = "~> 3.0"
  name                   = "${terraform.workspace}-genesis"
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  vpc_security_group_ids = [var.vpc_security_group_id]
  subnet_id              = var.vpc_subnet_id
  ebs_block_device       = [
    {
      device_name = "/dev/sdb"
      volume_type = "gp3"
      volume_size = 20
    }
  ]
  tags = {
    Environment = terraform.workspace
    Type        = "genesis"
  }
}

module "node_ec2_instances" {
  count                  = var.node_count
  source                 = "terraform-aws-modules/ec2-instance/aws"
  version                = "~> 3.0"
  name                   = "${terraform.workspace}-node-${count.index + 1}"
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  vpc_security_group_ids = [var.vpc_security_group_id]
  subnet_id              = var.vpc_subnet_id
  ebs_block_device       = [
    {
      device_name = "/dev/sdb"
      volume_type = "gp3"
      volume_size = 20
    }
  ]
  tags = {
    Environment = terraform.workspace
    Type        = "node"
  }
}

module "client_ec2_instance" {
  count                  = var.enable_client ? 1 : 0
  source                 = "terraform-aws-modules/ec2-instance/aws"
  version                = "~> 3.0"
  name                   = "${terraform.workspace}-client"
  ami                    = var.client_ami_id
  instance_type          = var.client_instance_type
  key_name               = var.key_pair_name
  vpc_security_group_ids = [var.vpc_security_group_id]
  subnet_id              = var.vpc_subnet_id
  tags = {
    Environment = terraform.workspace
    Type        = "client"
  }
}
