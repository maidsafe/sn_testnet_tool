resource "digitalocean_droplet" "testnet_genesis" {
  image    = "ubuntu-22-04-x64"
  name     = "${terraform.workspace}-safe-node-1"
  region   = var.region
  size     = var.node-size
  ssh_keys = var.ssh_keys

  connection {
    host        = self.ipv4_address
    user        = "root"
    type        = "ssh"
    timeout     = "5m"
    private_key = file(var.pvt_key)
  }

  provisioner "file" {
    source       = "scripts/init-node.sh"
    destination  = "/tmp/init-node.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/init-node.sh",
      "/tmp/init-node.sh \"${var.node_url}\" true \"${self.ipv4_address}\" \"${digitalocean_droplet.testnet_genesis.ipv4_address}\" \"${var.port}\" \"${var.remote_log_level}\" \"${terraform.workspace}-safe-node-1\" \"${var.otlp_collector_endpoint}\"",
 
    ]
  }

  provisioner "local-exec" {
    command = <<EOH
      echo "node-1 ${digitalocean_droplet.testnet_genesis.ipv4_address}" > workspace/${terraform.workspace}/ip-list
      echo ${digitalocean_droplet.testnet_genesis.ipv4_address} > workspace/${terraform.workspace}/genesis-ip
      rm -f workspace/${terraform.workspace}-network-contacts
      mkdir -p ~/.ssh/
      touch ~/.ssh/known_hosts
      ssh-keyscan -H ${digitalocean_droplet.testnet_genesis.ipv4_address} >> ~/.ssh/known_hosts
      rsync root@${digitalocean_droplet.testnet_genesis.ipv4_address}:~/network-contacts workspace/${terraform.workspace}/network-contacts
      rsync root@${digitalocean_droplet.testnet_genesis.ipv4_address}:~/genesis-key workspace/${terraform.workspace}/genesis-key
    EOH
  }
}
