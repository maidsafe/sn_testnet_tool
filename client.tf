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

  provisioner "remote-exec"  {
    script     = "./scripts/ELK/install-and-run-metricbeat.sh"
  }

  provisioner "file" {
    source      = "./scripts/init-client-node.sh"
    destination = "/tmp/init-client-node.sh"
  }


  provisioner "file"  {
    source      = "./scripts/loop_client_tests.sh"
    destination = "loop_client_tests.sh"
  }
  
  provisioner "file" {
    source      = "./tests/index"
    destination = "index"
  }
  provisioner "file" {
    source      = "./scripts/dl_files.sh"
    destination = "dl_files.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/init-client-node.sh",
      "/tmp/init-client-node.sh \"${var.repo_owner}\" \"${var.commit_hash}\"",
    ]
  }
  provisioner "file" {
    source      = "./safe"
    destination = "safe"
  }


  provisioner "remote-exec" {
    inline = [
     " echo \"Downloading test-data from s3://safe-test-data to test-data\"",
      "apt install wget unzip -y",
      "wget https://sn-node.s3.eu-west-2.amazonaws.com/the-test-data.zip",
      "unzip ./the-test-data.zip",
      "chmod +x ./safe",
      "cp ./safe /usr/local/bin/safe",
      "nohup time safe files put -r test-data &",
    ]
  }
  

  provisioner "local-exec" {
    command = <<EOH
      mkdir -p ~/.ssh/
      touch ~/.ssh/known_hosts
      echo ${self.ipv4_address} > ${terraform.workspace}-client-ip
      ssh-keyscan -H ${self.ipv4_address} >> ~/.ssh/known_hosts
      ./scripts/run_client_tests_for_workspace.sh
    EOH
  }
}
