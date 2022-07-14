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
        timeout = "10m"
        private_key = file(var.pvt_key)
        # agent=true
    }

    depends_on = [
      digitalocean_droplet.testnet_genesis,
    ]

    provisioner "remote-exec" {
      inline= [ "curl -so- https://raw.githubusercontent.com/maidsafe/safe_network/master/resources/scripts/install.sh | sudo bash" ]
    }


    provisioner "remote-exec" {
      script="scripts/ELK/install-and-run-metricbeat.sh"
      on_failure = continue
    }

    provisioner "remote-exec" {
      script="scripts/setup-node-dirs.sh"
    }
    
    provisioner "remote-exec" {
        inline = [
           "apt-get update",
            # don't add apt-install steps here. move them down before `cargo build` to prevent file locks
            # "bash",
            <<-EOT
                while sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1 ; do
                    sleep 1
                done
                while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 ; do
                    sleep 1
                done
                while sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1 ; do
                    sleep 1
                done
                while sudo fuser /var/lib/apt/lists/ >/dev/null 2>&1 ; do
                    sleep 1
                done
                if [ -f /var/log/unattended-upgrades/unattended-upgrades.log ]; then
                    while sudo fuser /var/log/unattended-upgrades/unattended-upgrades.log >/dev/null 2>&1 ; do
                    sleep 1
                    done
                fi
            EOT
        ]
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
      inline = [
      
          "git clone https://github.com/${var.repo_owner}/safe_network -q",
          "cd safe_network",
          "git checkout ${var.commit_hash}",
          "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -q --default-host x86_64-unknown-linux-gnu --default-toolchain stable --profile minimal -y",
          ". $HOME/.cargo/env",
          "apt update",
          "apt -qq install build-essential -y",
          # get those tests built first
          "cargo -q test --release -p sn_client --no-run",
      ]
    }
  

    provisioner "remote-exec" {
      on_failure = continue
      inline = [
        "echo 'Setting ENV vars'",
        "export RUST_LOG=sn_client=trace",
        "cargo test --release > test.log",
      ]
  }

  provisioner "local-exec" {
    command = <<EOH
      mkdir -p ~/.ssh/
      touch ~/.ssh/known_hosts
      echo ${self.ipv4_address} >> ${var.working_dir}/${terraform.workspace}-client-ip
      ssh-keyscan -H ${self.ipv4_address} >> ~/.ssh/known_hosts
    EOH
  }
}
