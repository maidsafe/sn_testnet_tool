resource "digitalocean_droplet" "testnet_client" {
  count    = var.client_count
  image    = "ubuntu-22-04-x64"
  name     = "${terraform.workspace}-safe-client-${count.index + 1}"
  region   = var.region
  size     = var.node-size
  ssh_keys = var.ssh_keys

  connection {
    host        = self.ipv4_address
    user        = "root"
    type        = "ssh"
    timeout     = "5m"
    private_key = file(var.pvt_key)
  }

  depends_on = [
    digitalocean_droplet.testnet_genesis,
  ]

  # upload the genesis node network contacts
  provisioner "file" {
    source      = "${terraform.workspace}-network-contacts"
    destination = "network_contacts"
  }

  provisioner "file" {
    source      = "./scripts/init-client-node.sh"
    destination = "/tmp/init-client-node.sh"
  }

  provisioner "file" {
    source      = "./scripts/loop_client_tests.sh"
    destination = "loop_client_tests.sh"
  }
  # TODO: readd once we have this set up again
  # provisioner "local-exec" {
  #   command = <<EOH
  #     echo "Downloading test-data from s3://safe-test-data to test-data"
  #     aws s3 cp \
  #       "s3://sn-node/test-data" \
  #       "test-data"
  #   EOH
  # }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/init-client-node.sh",
      "/tmp/init-client-node.sh \"${var.repo_owner}\" \"${var.commit_hash}\"",
    ]
  }

  provisioner "remote-exec" {
    script     = "scripts/ELK/install-and-run-metricbeat.sh"
    on_failure = continue
  }

  provisioner "local-exec" {
    command = <<EOH
      mkdir -p ~/.ssh/
      touch ~/.ssh/known_hosts
      echo ${self.ipv4_address} > ${terraform.workspace}-client-ip
      ssh-keyscan -H ${self.ipv4_address} >> ~/.ssh/known_hosts
    EOH
  }
}
