terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
  backend "s3" {
    bucket = "safe-testnet-tool"
    key    = "terraform.tfstate"
    region = "eu-west-2"
  }
}

variable "do_token" {}

variable "pvt_key" {}

variable "number_of_nodes" {
  default = "5"
}

variable "testnet_channel" {
  default = "public"
}

variable "working_dir" {}


variable "node_bin" {
  default = ""
}

variable "remote_log_level" {
  default = "-vvvv"
}

variable "node_bin_url" {
  default = "https://sn-node.s3.eu-west-2.amazonaws.com/sn_node-$node_version-x86_64-unknown-linux-musl.tar.gz"
}

variable "port" {
  type    = number
  default = 12000
}

variable "ssh_keys" {
  type    = list(number)
  default = [
    26204985, # David Irvine
    19315097, # Stephen Coyle
    29201567, # Josh Wilson
    29586082, # Gabriel Viganotti
    29690435, # Yogeshwar Murugan
    29690776, # Edward Holst
    30643220, # Chris Connelly
    30643816, # Anselme Grumbach
    30113222, # Qi Ma
    30878672, # Chris O'Neil
    31216015, # QA
    34183228, # GH Actions Automation
  ]
}

variable "region" {
  default = "lon1"
}

# droplet size and config, NOT node related
variable "build-size" {
  # default = "s-1vcpu-1gb"
  # default = "s-4vcpu-8gb"
  default = "s-8vcpu-16gb"
}

variable "node-size" {
  default = "s-2vcpu-4gb"
}


provider "digitalocean" {
  token = var.do_token
}

variable "builder_count" {
  default = "0"
}

variable "repo_owner" {
  default = "maidsafe"
}

variable "commit_hash" {
  default = "."
}
