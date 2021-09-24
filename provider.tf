terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      # version = "1.22.2"
    }
  }
  backend "s3" {
    bucket = "safe-testnet-tool"
    key    = "terraform.tfstate"
    region = "eu-west-2"
  }
}



variable "do_token" {}

# location of ssh key to log into nodes
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
  default = "-vvv"
}

variable "node_bin_url" {
  default = "https://sn-node.s3.eu-west-2.amazonaws.com/sn_node-$node_version-x86_64-unknown-linux-musl.tar.gz"
}

/// 1024mb by default
variable "max_capacity" {
  default = "1024 * 1024 * 1024"
}

variable "port" {
  type    = number
  default = 12000
}

variable "ssh_keys" {
  type    = list(number)
  default = [26400596,26204985,19315097,26204781,29201567,29586082,29690435,29690776,30643220,30643816,30113222,30878672,31216015]
}

variable "region" {
  default = "lon1"
}

# droplet size and config, NOT node related
variable "size" {
  # default = "s-1vcpu-1gb"
  default = "s-4vcpu-8gb"
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