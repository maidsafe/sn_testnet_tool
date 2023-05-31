resource "digitalocean_droplet" "node1-client" {
  image    = "ubuntu-22-04-x64"
  name     = "${terraform.workspace}-safe-node1-and-client"
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

  provisioner "file" {
    source       = "scripts/init-node.sh"
    destination  = "/tmp/init-node.sh"
  }

  provisioner "file" {
    source      = "./workspace/${terraform.workspace}/safe"
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
    ]
  }
  

  provisioner "file" {
    source       = "workspace/${terraform.workspace}/node-1"
    destination  = "/contact-node-peer-id"
  }


  provisioner "local-exec" {
    command = <<EOH
      mkdir -p ~/.ssh/
      touch ~/.ssh/known_hosts
      echo "droplet-1 ${self.ipv4_address}" >> workspace/${terraform.workspace}/ip-list
      ssh-keyscan -H ${self.ipv4_address} >> ~/.ssh/known_hosts
    EOH
  }

  # user_data = data.terraform_remote_state.node.outputs[0]
  
    # For a non-genesis node, we pass an empty value for the node IP address.
  # It looks a bit awkward because you have to escape the double quotes.
  provisioner "remote-exec" {
    inline = [
      "sudo DEBIAN_FRONTEND=noninteractive apt install ripgrep -y > /dev/null 2>&1",
      "chmod +x /tmp/init-node.sh",
      "echo \"nodes per.... ${var.number_of_nodes_per_machine}\"",
      "/tmp/init-node.sh \"${var.node_url}\" \"${var.port}\" \"${terraform.workspace}-safe-node-1\" ${self.ipv4_address}",
      "rg \"node is listening on \".+\"\" > /tmp/output.txt",
    ]
  }

    # rg for non local ip, and then grab teh whole line, but remove the last character
  provisioner "local-exec" {
         command = "rsync -z root@${self.ipv4_address}:/tmp/output.txt ./workspace/${terraform.workspace}/node-1-listeners"
       
    }

    # this file is missing /ip4/ at the beginning of the multiaddr line, so we add it later
  provisioner "local-exec" {
         command = "rg --pcre2 -i '\\b((?!10\\.|172\\.(1[6-9]|2\\d|3[01])\\.|192\\.168\\.|169\\.254\\.|127\\.0\\.0\\.1)[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+).+' workspace/${terraform.workspace}/node-1-listeners -o | sed 's/.$//' > ./workspace/${terraform.workspace}/contact-node"
    }
}

resource "digitalocean_droplet" "node" {
  count    = var.number_of_droplets - 1
  image    = "ubuntu-22-04-x64"
  name     = "${terraform.workspace}-safe-node-${count.index + 2}" // 2 because 0 index + initial node1
  region   = var.region
  size     = var.node-size
  ssh_keys = var.ssh_keys
  depends_on = [digitalocean_droplet.node1-client]
  
  connection {
    host        = self.ipv4_address
    user        = "root"
    type        = "ssh"
    timeout     = "5m"
    private_key = file(var.pvt_key)
  }

  provisioner "file" {
    source       = "scripts/init-node.sh"
    destination  = "/tmp/init-node.sh"
  }

  # # For a non-genesis node, we pass an empty value for the node IP address.
  # # It looks a bit awkward because you have to escape the double quotes.
  # provisioner "local-exec" {
  #   command =   "echo /ip4/$(cat workspace/${terraform.workspace}/contact-node) > workspace/${terraform.workspace}/contact-node-peer-id"
  # }

  provisioner "file" {
    source       = "workspace/${terraform.workspace}/contact-node"
    destination  = "/contact-node-peer-id"
  }


  provisioner "local-exec" {
    command = <<EOH
      mkdir -p ~/.ssh/
      touch ~/.ssh/known_hosts
      echo "droplet-${count.index + 2} ${self.ipv4_address}" >> workspace/${terraform.workspace}/ip-list
      ssh-keyscan -H ${self.ipv4_address} >> ~/.ssh/known_hosts
    EOH
  }

  
  # For a non-genesis node, we pass an empty value for the node IP address.
  # It looks a bit awkward because you have to escape the double quotes.
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/init-node.sh",
      "/tmp/init-node.sh \"${var.node_url}\" \"${var.port}\" \"${terraform.workspace}-safe-node-${count.index + 2}\" ${self.ipv4_address} \"/ip4/$(cat /contact-node-peer-id)\" ${var.number_of_nodes_per_machine}",
    ]
  }

}