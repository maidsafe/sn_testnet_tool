resource "digitalocean_droplet" "testnet_genesis" {
    image = "ubuntu-18-04-x64"
    name = "${terraform.workspace}-safe-node-genesis"
    region = var.region
    size = var.node-size
    ssh_keys = var.ssh_keys

    connection {
        host = self.ipv4_address
        user = "root"
        type = "ssh"
        timeout = "3m"
        # agent=true
        private_key = file(var.pvt_key)
    }



    provisioner "remote-exec" {
      script=  var.node_bin == "" ? "scripts/download-node.sh" : "./single-machine-testnet.sh"
    }

    provisioner "file" {
      # if no bin defined, we put up (existing 'single-machine-testnet.sh'), which we dont use... it's just some placeholder and we dont need it hereafter
      source      = var.node_bin == "" ? "single-machine-testnet.sh" : var.node_bin
      destination = var.node_bin == "" ? "single-machine-testnet.sh" : "sn_node"
    }

    provisioner "remote-exec" {
      script="scripts/setup-node-dirs.sh"
    }

    provisioner "remote-exec" {
      script="scripts/ELK/install-and-run-metricbeat.sh"
      on_failure = continue
    }

    provisioner "remote-exec" {
      inline = [
        "echo 'Setting ENV vars'",
        "export RUST_LOG=sn_node=trace,sn_dysfuction=debug",
        "export TOKIO_CONSOLE_BIND=${digitalocean_droplet.testnet_genesis.ipv4_address}:6669",
        "nohup ./sn_node --first --local-addr ${digitalocean_droplet.testnet_genesis.ipv4_address}:${var.port} --skip-auto-port-forwarding --root-dir ~/node_data --log-dir ~/logs ${var.remote_log_level} &",
        "sleep 5",
        "cp -H ~/.safe/prefix_maps/default ~/prefix-map",
      "sleep 5;"
    ]
  }

   provisioner "local-exec" {
    command = <<EOH
      echo ${digitalocean_droplet.testnet_genesis.ipv4_address} > ${var.working_dir}/${terraform.workspace}-ip-list
      echo ${digitalocean_droplet.testnet_genesis.ipv4_address} > ${var.working_dir}/${terraform.workspace}-genesis-ip
      rm ${var.working_dir}/${terraform.workspace}-prefix-map || true
      mkdir -p ~/.ssh/
      touch ~/.ssh/known_hosts
      ssh-keyscan -H ${digitalocean_droplet.testnet_genesis.ipv4_address} >> ~/.ssh/known_hosts
      rsync root@${digitalocean_droplet.testnet_genesis.ipv4_address}:~/prefix-map ${var.working_dir}/${terraform.workspace}-prefix-map
    EOH
         
  }
}
