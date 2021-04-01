resource "digitalocean_droplet" "sn_genesis" {
    image = "ubuntu-18-04-x64"
    name = "safe-node-genesis"
    region = var.region
    size = var.size
    private_networking = true
    ssh_keys = var.ssh_keys

    connection {
        host = self.ipv4_address
        user = "root"
        type = "ssh"
        timeout = "2m"
        private_key = file(var.pvt_key)
    }


    provisioner "remote-exec" {
      script=  var.node_bin == "" ? "src/download-node.sh" : ""
    }

    provisioner "file" {
      # if no bin defined, we put up (existing 'up.sh') junk and dont care about it anymore
      source      = var.node_bin == "" ? "up.sh" : var.node_bin
      destination = var.node_bin == "" ? "up.sh" : "sn_node"
    }

    provisioner "remote-exec" {
      script="src/setup-node-dirs.sh"
    }

    provisioner "remote-exec" {
    inline = [
      "echo 'Setting ENV vars'",
      "export ${var.remote_log_level}",
      # "export RUST_BACKTRACE=1",
      # Do we still need rm here? wouldn't exist at this point
      "nohup 2>&1 ./sn_node --first --external-ip ${digitalocean_droplet.sn_genesis.ipv4_address} --root-dir ~/node_data -vvvvv &",
      "sleep 5;"
    ]
  }

   provisioner "local-exec" {
    command = "echo ${digitalocean_droplet.sn_genesis.ipv4_address} > ip-list"
         
  }

   provisioner "local-exec" {
    command = "echo ${digitalocean_droplet.sn_genesis.ipv4_address} > genesis-ip"
         
  }
}