terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
  backend "s3" {
    key    = "sn-testnet-tool-digital-ocean.tfstate"
  }
}

resource "digitalocean_droplet" "genesis" {
  image    = var.droplet_image
  name     = "${terraform.workspace}-genesis"
  region   = var.region
  size     = var.droplet_size
  ssh_keys = var.droplet_ssh_keys
  tags     = ["environment:${terraform.workspace}", "type:genesis"]
}

resource "digitalocean_droplet" "node" {
  count    = var.node_count
  image    = var.droplet_image
  name     = "${terraform.workspace}-node-${count.index + 1}"
  region   = var.region
  size     = var.droplet_size
  ssh_keys = var.droplet_ssh_keys
  tags     = ["environment:${terraform.workspace}", "type:node"]
}

resource "digitalocean_droplet" "build" {
  count    = var.use_custom_bin ? 1 : 0
  image    = var.droplet_image
  name     = "${terraform.workspace}-build"
  region   = var.region
  size     = var.build_machine_size
  ssh_keys = var.droplet_ssh_keys
  tags     = ["environment:${terraform.workspace}", "type:build"]
}