resource "digitalocean_droplet" "node_builder" {
    count = var.builder_count
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
            "git clone https://github.com/${var.repo_owner}/safe_network -q",
            "cd safe_network",
            "git checkout ${var.commit_hash}",
            "apt -qq update",
            "while fuser /var/{lib/{dpkg,apt/lists},cache/apt/archives}/lock >/dev/null 2>&1; do sleep 1; done",
            "apt -qq install musl-tools -y ",
            "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -q --default-host x86_64-unknown-linux-gnu --default-toolchain stable --profile minimal -y",
            ". $HOME/.cargo/env",
            "rustup target add x86_64-unknown-linux-musl",
            "cargo -q build --release --target=x86_64-unknown-linux-musl",
        ]
    }

    provisioner "local-exec" {
        command = <<EOH
            mkdir -p ~/.ssh/
            touch ~/.ssh/known_hosts
            ssh-keyscan -H ${self.ipv4_address} >> ~/.ssh/known_hosts
            rsync root@${self.ipv4_address}:/root/safe_network/target/x86_64-unknown-linux-musl/release/sn_node ${var.working_dir}
        EOH
    }
}