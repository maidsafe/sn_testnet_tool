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
        #private_key = file(var.pvt_key)
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
      # "export RUST_BACKTRACE=1",
      # Do we still need rm here? wouldn't exist at this point
      "nohup ./sn_node --first ${digitalocean_droplet.testnet_genesis.ipv4_address}:${var.port} --skip-igd --root-dir ~/node_data ${var.remote_log_level} --log-dir ~/logs &",
      "sleep 5;"
    ]
  }

   provisioner "local-exec" {
    command = "echo ${digitalocean_droplet.testnet_genesis.ipv4_address} > ${terraform.workspace}-ip-list"
         
  }

   provisioner "local-exec" {
    command = "echo ${digitalocean_droplet.testnet_genesis.ipv4_address} > ${terraform.workspace}-genesis-ip"
         
  }
}