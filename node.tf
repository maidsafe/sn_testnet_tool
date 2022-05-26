resource "digitalocean_droplet" "testnet_node" {
    # count = 5
    count = var.number_of_nodes
    image = "ubuntu-18-04-x64"
    name = "${terraform.workspace}-safe-node-${count.index + 1}"
    region = var.region
    size = var.node-size
    ssh_keys = var.ssh_keys

    connection {
        host = self.ipv4_address
        user = "root"
        type = "ssh"
        timeout = "10m"
        private_key = file(var.pvt_key)
        # agent=true
    }

    depends_on = [
      digitalocean_droplet.testnet_genesis,
    ]

    provisioner "remote-exec" {
      script=  var.node_bin == "" ? "scripts/download-node.sh" : "./single-machine-testnet.sh"
      on_failure = continue
    }

    provisioner "file" {
      # if no bin defined, we put up (existing 'single-machine-testnet.sh') which we dont use... it's just some placeholder and we dont need it hereafter
      source      = var.node_bin == "" ? "single-machine-testnet.sh" : var.node_bin
      destination = var.node_bin == "" ? "single-machine-testnet.sh" : "sn_node"
      on_failure = continue
    }


    provisioner "remote-exec" {
      script="scripts/setup-node-dirs.sh"
    }

    provisioner "remote-exec" {
      script="scripts/ELK/install-and-run-metricbeat.sh"
      on_failure = continue
    }

    provisioner "local-exec" {
      command = <<EOH
        if ! [ -f ${var.working_dir}/${terraform.workspace}-prefix-map ]; then
          echo "Downloading from s3://safe-testnet-tool/${terraform.workspace}-prefix-map to ${var.working_dir}/${terraform.workspace}-prefix-map"
          aws s3 cp \
            "s3://safe-testnet-tool/${terraform.workspace}-prefix-map" \
            "${var.working_dir}/${terraform.workspace}-prefix-map"
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


    # upload the genesis node prefix map
    provisioner "file" {
      source      = "${var.working_dir}/${terraform.workspace}-prefix-map"
      destination = "prefix-map"
    }

     provisioner "remote-exec" {
      inline = [
        "echo moving prefix_map to correct location",
        "cp prefix-map ~/.safe/prefix_maps/prefix-map",
        "echo Creating a symlink to default",
        "ln -s ~/.safe/prefix_maps/prefix-map ~/.safe/prefix_maps/default"
      ]

    }

    provisioner "remote-exec" {
      on_failure = continue
      inline = [
        "echo 'Setting ENV vars'",
        "export RUST_LOG=sn_node=trace,sn_dysfuction=debug",
        "export TOKIO_CONSOLE_BIND=${self.ipv4_address}:6669",
        "sleep 5",
        "echo \" node command is: sn_node --root-dir ~/node_data --skip-auto-port-forwarding ${var.remote_log_level} --log-dir ~/logs &\"",
        # sleep random number between 10 and 60s to not barrage dkg
        "sleep $(shuf -i 10-90 -n 1)",
        "now=$(date)",
        "echo \"starting node at $now\"",
        "nohup ./sn_node --root-dir ~/node_data --skip-auto-port-forwarding --log-dir ~/logs --local-addr ${self.ipv4_address}:${var.port} ${var.remote_log_level} &",
        # wait 5s so node starts fully before we continue
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
    EOH
  }
}
