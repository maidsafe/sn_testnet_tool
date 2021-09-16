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
        "export RUST_LOG=safe_network=trace,qp2p=trace",
        "nohup ./sn_node --first --local-addr ${digitalocean_droplet.testnet_genesis.ipv4_address}:${var.port} --skip-igd --root-dir ~/node_data --log-dir ~/logs --json-logs &",
      "sleep 5;"
    ]
  }

    # doesnt work yet
    #case "$OSTYPE" in
    #  darwin*)  curl -o jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-osx-amd64 ;; 
    #  linux*)   curl -o jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 ;;
    #  msys*)    curl -o jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-win64.exe ;;
    #  cygwin*)  curl -o jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-win64.exe ;;
    #  *)        echo "unknown OS: $OSTYPE" ;;
    #esac

   provisioner "local-exec" {
    command = <<EOH
      echo ${digitalocean_droplet.testnet_genesis.ipv4_address} > ${terraform.workspace}-ip-list
      echo ${digitalocean_droplet.testnet_genesis.ipv4_address} > ${terraform.workspace}-genesis-ip
      rm ${terraform.workspace}-node_connection_info.config
      ssh-keyscan -H ${digitalocean_droplet.testnet_genesis.ipv4_address} >> ~/.ssh/known_hosts
      rsync root@${digitalocean_droplet.testnet_genesis.ipv4_address}:~/.safe/node/node_connection_info.config ${terraform.workspace}-node_connection_info.config
      curl -L -o jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
      chmod 0755 jq
    EOH
         
  }
}
