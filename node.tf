resource "digitalocean_droplet" "sn_node" {
    # count = 5
    count = var.number_of_nodes
    image = "ubuntu-18-04-x64"
    name = "safe-node-${count.index + 1}"
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

    # depends_on = [
    #   digitalocean_droplet.sn_genesis,
    # ]

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
      "MAX_CAPACITY=$((${var.max_capacity}))",
      "HARD_CODED_CONTACTS='[\"${digitalocean_droplet.sn_genesis.ipv4_address}:${var.port}\"]'",
      "echo hcc-$HARD_CODED_CONTACTS",
      "sleep 5",
      # "sleep $((${count.index * 2}));",
      "echo \"Starting node w/ capacity $MAX_CAPACITY\"",
      "echo \" node command is: sn_node --max-capacity $MAX_CAPACITY --root-dir ~/node_data --hard-coded-contacts $HARD_CODED_CONTACTS -vvvvv --local-ip ${self.ipv4_address} --local-port ${var.port} --external-ip ${self.ipv4_address} --external-port ${var.port}  &\"",
      "nohup 2>&1 ./sn_node --max-capacity $MAX_CAPACITY --root-dir ~/node_data --hard-coded-contacts $HARD_CODED_CONTACTS -vvvvv --local-ip ${self.ipv4_address} --local-port ${var.port} --external-ip ${self.ipv4_address} --external-port ${var.port} &",
      "sleep 5",
      "echo 'node ${count.index + 1} set up'"
    ]
  }

  provisioner "local-exec" {
    command = "echo ${self.ipv4_address} >> ip-list"
  }
}