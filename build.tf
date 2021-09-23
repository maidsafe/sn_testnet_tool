resource "digitalocean_droplet" "node_builder" {
    image = "ubuntu-20-04-x64"
    name = "${terraform.workspace}-safe-node-builder"
    region = "lon1"
    size = "s-8vcpu-16gb"
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
        inline = [
            "git clone https://github.com/maidsafe/safe_network --depth 1 -q",
            "cd safe_network",
            "apt -qq update",
            "sleep 50",
            "apt -qq install musl-tools -y ",
            "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --default-host x86_64-unknown-linux-gnu --default-toolchain stable --profile minimal -y -q",
            ". $HOME/.cargo/env",
            "rustup target add x86_64-unknown-linux-musl",
            "cargo -V",
            "cargo build --release --target=x86_64-unknown-linux-musl",
        ]
    }

    provisioner "local-exec" {
        command = <<EOH
            mkdir -p ~/.ssh/
            touch ~/.ssh/known_hosts
            ssh-keyscan -H ${digitalocean_droplet.node_builder.ipv4_address} >> ~/.ssh/known_hosts
            rsync root@${digitalocean_droplet.node_builder.ipv4_address}:/root/safe_network/target/x86_64-unknown-linux-musl/release/sn_node .
        EOH
    }
}