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

variable "node_bin" {
  default = ""
}

# eg RUST_LOG=sn_node=trace
variable "remote_log_level" {
  default = "RUST_LOG=sn_node=trace"
  # default = "RUST_LOG=sn_node=trace,sn_routing=debug,qp2p=debug"
}

variable "node_bin_url" {
  default = "https://sn-node.s3.eu-west-2.amazonaws.com/sn_node-$node_version-x86_64-unknown-linux-musl.tar.gz"
}

variable "max_capacity" {
  default = "2 * 1024 * 1024"
}

variable "port" {
  type    = number
  default = 12000
}

variable "ssh_keys" {
  type    = list(number)
  default = [26400596,26204985,26204991,19315097,26204781,29201567,29586082,29690435,29690776]
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
