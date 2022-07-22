resource "digitalocean_droplet" "testnet_node" {
  count    = var.number_of_nodes
  image    = "ubuntu-22-04-x64"
  name     = "${terraform.workspace}-safe-node-${count.index + 2}" // 2 because 0 index, and genesis is node 1
  region   = var.region
  size     = var.node-size
  ssh_keys = var.ssh_keys

  connection {
    host        = self.ipv4_address
    user        = "root"
    type        = "ssh"
    timeout     = "1m"
    private_key = file(var.pvt_key)
  }

  depends_on = [
    digitalocean_droplet.testnet_genesis,
  ]

  # upload the genesis node prefix map
  provisioner "file" {
    source      = "${terraform.workspace}-prefix-map"
    destination = "prefix-map"
  }

  provisioner "file" {
    source       = "scripts/init-node.sh"
    destination  = "/tmp/init-node.sh"
  }

  # For a non-genesis node, we pass an empty value for the node IP address.
  # It looks a bit awkward because you have to escape the double quotes.
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/init-node.sh",
      "/tmp/init-node.sh \"${var.node_url}\" false \"${self.ipv4_address}\" \"\" \"${var.port}\" \"${var.remote_log_level}\"",
    ]
  }

  provisioner "remote-exec" {
    script      = "scripts/ELK/install-and-run-metricbeat.sh"
    on_failure  = continue
  }

  provisioner "local-exec" {
    command = <<EOH
      if ! [ -f ${terraform.workspace}-prefix-map ]; then
        echo "Downloading from s3://safe-testnet-tool/${terraform.workspace}-prefix-map to ${terraform.workspace}-prefix-map"
        aws s3 cp \
          "s3://safe-testnet-tool/${terraform.workspace}-prefix-map" \
          "${terraform.workspace}-prefix-map"
      fi
      if ! [ -f ${terraform.workspace}-ip-list ]; then
        echo "Downloading from s3://safe-testnet-tool/${terraform.workspace}-ip-list to ${terraform.workspace}-ip-list"
        aws s3 cp \
          "s3://safe-testnet-tool/${terraform.workspace}-ip-list" \
          "${terraform.workspace}-ip-list"
      fi
      if ! [ -f ${terraform.workspace}-genesis-ip ]; then
      echo "Downloading from s3://safe-testnet-tool/${terraform.workspace}-genesis-ip to ${terraform.workspace}-genesis-ip"
        aws s3 cp \
          "s3://safe-testnet-tool/${terraform.workspace}-genesis-ip" \
          "${terraform.workspace}-genesis-ip"
      fi
    EOH
  }

  provisioner "local-exec" {
    command = <<EOH
      mkdir -p ~/.ssh/
      touch ~/.ssh/known_hosts
      echo "node-${count.index + 2} ${self.ipv4_address}" >> ${terraform.workspace}-ip-list
      ssh-keyscan -H ${self.ipv4_address} >> ~/.ssh/known_hosts
    EOH
  }
}
