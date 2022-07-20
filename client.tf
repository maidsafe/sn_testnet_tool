resource "digitalocean_droplet" "testnet_client" {
    count = 1
    image = "ubuntu-22-04-x64"
    name = "${terraform.workspace}-safe-client-${count.index + 1}"
    region = var.region
    size = var.node-size
    ssh_keys = var.ssh_keys

    connection {
        host = self.ipv4_address
        user = "root"
        type = "ssh"
        timeout = "1m"
        private_key = file(var.pvt_key)
        # agent=true
    }

    depends_on = [
      digitalocean_droplet.testnet_genesis,
    ]

    provisioner "remote-exec" {
      script="scripts/ELK/install-and-run-metricbeat.sh"
      on_failure = continue
    }

    provisioner "remote-exec" {
      script="scripts/setup-node-dirs.sh"
    }
    

    provisioner "local-exec" {
      command = <<EOH
        if ! [ -f ${var.working_dir}/${terraform.workspace}-prefix-map ]; then
          echo "Downloading from s3://safe-testnet-tool/${terraform.workspace}-prefix-map to ${var.working_dir}/${terraform.workspace}-prefix-map"
          aws s3 cp \
            "s3://safe-testnet-tool/${terraform.workspace}-prefix-map" \
            "${var.working_dir}/${terraform.workspace}-prefix-map"
        fi
      EOH
    }
   
    provisioner "local-exec" {
      command = <<EOH
          echo "Downloading test-data from s3://safe-test-data to ${var.working_dir}/test-data"
          aws s3 cp \
            "s3://safe-test-data" \
            "${var.working_dir}/test-data"
      EOH
    }


    # upload the genesis node prefix map
    provisioner "file" {
      source      = "${var.working_dir}/${terraform.workspace}-prefix-map"
      destination = "prefix-map"
    }
    # upload run client test script
    provisioner "file" {
      source      = "./scripts/build_client_tests.sh"
      destination = "build_client_tests.sh"
    }

    # upload loop client test script
    provisioner "file" {
      source      = "./scripts/loop_client_tests.sh"
      destination = "loop_client_tests.sh"
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
      inline = [
      
          "git clone https://github.com/${var.repo_owner}/safe_network -q",
          "cd safe_network/sn_client",
          "git checkout ${var.commit_hash}",
          "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -q --default-host x86_64-unknown-linux-gnu --default-toolchain stable --profile minimal -y",
          ". $HOME/.cargo/env",
          "apt update",
          "apt -qq install build-essential ripgrep -y",
      ]
      on_failure=continue
    }
  

    provisioner "remote-exec" {
      on_failure = continue
      inline = [
        "echo 'Setting ENV vars'",
        "export RUST_LOG=sn_client=trace",
        "chmod +x ./build_client_tests.sh",
        "chmod +x ./loop_client_tests.sh",
        "./build_client_tests.sh"
      ]
  }

  provisioner "local-exec" {
    command = <<EOH
      mkdir -p ~/.ssh/
      touch ~/.ssh/known_hosts
      echo ${self.ipv4_address} > ${var.working_dir}/${terraform.workspace}-client-ip
      ssh-keyscan -H ${self.ipv4_address} >> ~/.ssh/known_hosts
    EOH
  }
}
