resource "digitalocean_droplet" "testnet_genesis" {
    image = "ubuntu-18-04-x64"
    name = "${terraform.workspace}-safe-node-genesis"
    region = var.region
    size = var.size
    private_networking = true
    ssh_keys = var.ssh_keys

    connection {
        host = self.ipv4_address
        user = "root"
        type = "ssh"
        timeout = "10m"
        private_key = file(var.pvt_key)
    }



    provisioner "remote-exec" {
      script=  var.node_bin == "" ? "src/download-node.sh" : "./nonsense.sh"
    }

    provisioner "file" {
      # if no bin defined, we put up (existing 'nonsense.sh') junk and dont care about it anymore
      source      = var.node_bin == "" ? "nonsense.sh" : var.node_bin
      destination = var.node_bin == "" ? "nonsense.sh" : "sn_node"
    }

    provisioner "remote-exec" {
      script="src/setup-node-dirs.sh"
    }

    provisioner "remote-exec" {
      inline = [
        "echo 'Setting ENV vars'",
        # "export RUST_LOG=safe_network=trace",
        "nohup ./sn_node --first --local-addr ${digitalocean_droplet.testnet_genesis.ipv4_address}:${var.port} --skip-igd --root-dir ~/node_data --log-dir ~/logs --json-logs &",
      "sleep 5;"
    ]
  }

   provisioner "local-exec" {
    command = <<EOH
      echo ${digitalocean_droplet.testnet_genesis.ipv4_address} > ${terraform.workspace}-ip-list
      echo ${digitalocean_droplet.testnet_genesis.ipv4_address} > ${terraform.workspace}-genesis-ip
      rm ${terraform.workspace}-node_connection_info.config || true
      mkdir -p ~/.ssh/
      touch ~/.ssh/known_hosts
      ssh-keyscan -H ${digitalocean_droplet.testnet_genesis.ipv4_address} >> ~/.ssh/known_hosts
      rsync root@${digitalocean_droplet.testnet_genesis.ipv4_address}:~/.safe/node/node_connection_info.config ${terraform.workspace}-node_connection_info.config
    EOH
         
  }
}
