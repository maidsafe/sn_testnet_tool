resource "digitalocean_droplet" "testnet_node" {
    # count = 5
    count = var.number_of_nodes
    image = "ubuntu-18-04-x64"
    name = "${terraform.workspace}-safe-node-${count.index + 1}"
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

    # depends_on = [
    #   digitalocean_droplet.testnet_genesis,
    # ]

    provisioner "remote-exec" {
      script=  var.node_bin == "" ? "src/download-node.sh" : "./nonsense.sh"
      on_failure = continue
    }

    provisioner "file" {
      # if no bin defined, we put up (existing 'nonsense.sh') junk and dont care about it anymore
      source      = var.node_bin == "" ? "nonsense.sh" : var.node_bin
      destination = var.node_bin == "" ? "nonsense.sh" : "sn_node"
      on_failure = continue
    }

    provisioner "remote-exec" {
      script="src/setup-node-dirs.sh"
      on_failure = continue
    }

    provisioner "remote-exec" {
      on_failure = continue
      inline = [
        "echo 'Setting ENV vars'",
        # "export RUST_BACKTRACE=1",
        "MAX_CAPACITY=$((${terraform.workspace == "public" ? "1024 * 1024 * 512"  : var.max_capacity}))",
        "HARD_CODED_CONTACTS='[\"${digitalocean_droplet.testnet_genesis.ipv4_address}:${var.port}\"]'",
        "echo hcc-$HARD_CODED_CONTACTS",
        "sleep 5",
        # "sleep $((${count.index * 2}));",
        "echo \"Starting node w/ capacity $MAX_CAPACITY\"",
        "echo \" node command is: sn_node --max-capacity $MAX_CAPACITY --root-dir ~/node_data --hard-coded-contacts $HARD_CODED_CONTACTS --skip-igd ${var.remote_log_level} --log-dir ~/logs --json-logs &\"",
        "nohup ./sn_node --max-capacity $MAX_CAPACITY --root-dir ~/node_data --hard-coded-contacts $HARD_CODED_CONTACTS --skip-igd ${var.remote_log_level} --log-dir ~/logs --json-logs --local-addr ${self.ipv4_address}:${var.port} &",
        "sleep 5",
        "echo 'node ${count.index + 1} set up'"
      ]
  }

  provisioner "local-exec" {
    command = "echo ${self.ipv4_address} >> ${terraform.workspace}-ip-list"
    on_failure = continue
  }

  # provisioner "local-exec" {
  #   when    = destroy
  #   command = "sed -i '/${self.ipv4_address}/d' ip-list"
  # }
}
