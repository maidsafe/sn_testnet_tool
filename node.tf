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

    # upload the genesis node config
    provisioner "file" {
      source      = "./${terraform.workspace}-node_connection_info.config"
      destination = "~/.safe/node/node_connection_info.config"
      # on_failure = continue
    }
    provisioner "remote-exec" {
      on_failure = continue
      inline = [
        "echo 'Setting ENV vars'",
        "export RUST_LOG=safe_network=trace,qp2p=trace",
        "MAX_CAPACITY=$((${terraform.workspace == "public" ? "1024 * 1024 * 512"  : var.max_capacity}))",
        "sleep 5",
        # "sleep $((${count.index * 2}));",
        "echo \"Starting node w/ capacity $MAX_CAPACITY\"",
        "echo \" node command is: sn_node --max-capacity $MAX_CAPACITY --root-dir ~/node_data --skip-igd ${var.remote_log_level} --log-dir ~/logs --json-logs &\"",
        "nohup ./sn_node --max-capacity $MAX_CAPACITY --root-dir ~/node_data --skip-igd --log-dir ~/logs --json-logs --local-addr ${self.ipv4_address}:${var.port} &",
        "sleep 5",
        "echo 'node ${count.index + 1} set up'"
      ]
  }

   provisioner "local-exec" {
    command = "ssh-keyscan -H ${digitalocean_droplet.testnet_genesis.ipv4_address} >> ~/.ssh/known_hosts"
         
  }

  provisioner "local-exec" {
    command = "echo ${self.ipv4_address} >> ${var.working_dir}/${terraform.workspace}-ip-list"
    on_failure = continue
  }

  # lets register ssh key locally
   provisioner "local-exec" {
    command = "ssh-keyscan -H ${digitalocean_droplet.testnet_genesis.ipv4_address} >> ~/.ssh/known_hosts"
  }

  provisioner "local-exec" {
    command = "tmp_config=$(mktemp /tmp/config.XXXXXXXXX) && cat ${terraform.workspace}-node_connection_info.config | awk -v socket=${"${self.ipv4_address}"}:1200\"\" 'NR==4{print socket\",\"}1' > $tmp_config && mv $tmp_config ${terraform.workspace}-node_connection_info.config"
    # command = "cat ${terraform.workspace}-node_connection_info.config | awk -v ip=$socket 'NR==4{print socket}1' > $TMPDIR/temp-config && mv $TMPDIR/temp-config ${terraform.workspace}-node_connection_info.config"
    # on_failure = continue
  }

  # provisioner "local-exec" {
  #   when    = destroy
  #   command = "sed -i '/${self.ipv4_address}/d' ip-list"
  # }
}
