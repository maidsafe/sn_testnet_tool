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

    depends_on = [
      digitalocean_droplet.testnet_genesis,
    ]

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

    provisioner "local-exec" {
      command = <<EOH
        if ! [ -f ${var.working_dir}/${terraform.workspace}-node_connection_info.config ]; then
          echo "Downloading from s3://safe-testnet-tool/${terraform.workspace}-node_connection_info.config to ${var.working_dir}/${terraform.workspace}-node_connection_info.config"
          aws s3 cp \
            "s3://safe-testnet-tool/${terraform.workspace}-node_connection_info.config" \
            "${var.working_dir}/${terraform.workspace}-node_connection_info.config"
        fi
        if ! [ -f ${var.working_dir}/${terraform.workspace}-ip-list ]; then
          echo "Downloading from s3://safe-testnet-tool/${terraform.workspace}-ip-list to ${var.working_dir}/${terraform.workspace}-ip-list"
          aws s3 cp \
            "s3://safe-testnet-tool/${terraform.workspace}-ip-list" \
            "${var.working_dir}/${terraform.workspace}-ip-list"
        fi
        if ! [ -f ${var.working_dir}/${terraform.workspace}-genesis-ip ]; then
        echo "Downloading from s3://safe-testnet-tool/${terraform.workspace}-genesis-ip to ${var.working_dir}/${terraform.workspace}-genesis-ip"
          aws s3 cp \
            "s3://safe-testnet-tool/${terraform.workspace}-genesis-ip" \
            "${var.working_dir}/${terraform.workspace}-genesis-ip"
        fi
      EOH
    }

    # upload the genesis node config
    provisioner "file" {
      source      = "${var.working_dir}/${terraform.workspace}-node_connection_info.config"
      destination = "~/.safe/node/node_connection_info.config"
    }

    provisioner "remote-exec" {
      on_failure = continue
      inline = [
        "echo 'Setting ENV vars'",
        # "export RUST_LOG=safe_network=trace,qp2p=trace",
        "MAX_CAPACITY=$((${terraform.workspace == "public" ? "1024 * 1024 * 512"  : var.max_capacity}))",
        "sleep 5",
        # "sleep $((${count.index * 2}));",
        "echo \"Starting node w/ capacity $MAX_CAPACITY\"",
        "echo \" node command is: sn_node --max-capacity $MAX_CAPACITY --root-dir ~/node_data --skip-igd ${var.remote_log_level} --log-dir ~/logs --json-logs &\"",
        "nohup ./sn_node --max-capacity $MAX_CAPACITY --root-dir ~/node_data --skip-igd --log-dir ~/logs --json-logs --local-addr ${self.ipv4_address}:${var.port} ${var.remote_log_level}  &",
        "sleep 5",
        "echo 'node ${count.index + 1} set up'"
      ]
  }

  provisioner "local-exec" {
    command = <<EOH
      mkdir -p ~/.ssh/
      touch ~/.ssh/known_hosts
      echo ${self.ipv4_address} >> ${var.working_dir}/${terraform.workspace}-ip-list
      ssh-keyscan -H ${self.ipv4_address} >> ~/.ssh/known_hosts
      echo $(jq ".[1] += [\"${self.ipv4_address}:${var.port}\"]" ${var.working_dir}/${terraform.workspace}-node_connection_info.config) > ${var.working_dir}/${terraform.workspace}-node_connection_info.config
    EOH
  }
}
