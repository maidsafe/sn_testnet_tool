FROM --platform=linux/amd64 python:3.11.3-bullseye

COPY entrypoint.sh /entrypoint.sh
RUN apt-get update -y && \
    apt-get install -y bsdmainutils curl jq less unzip && \
    adduser --disabled-password --gecos '' runner && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install --update && \
    rm -rf aws awscliv2.zip && \
    TERRAFORM_VERSION=$(curl -s https://checkpoint-api.hashicorp.com/v1/check/terraform | jq -r .current_version) && \
    curl https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
      -o terraform.zip && \
    unzip terraform.zip && \
    mv terraform /usr/local/bin/ && \
    rm terraform.zip && \
    echo "export PATH=\$PATH:/home/runner/.local/bin" >> /home/runner/.bashrc

USER runner
WORKDIR /home/runner
RUN pip install --user ansible boto3 && \
  curl -L -O https://static.rust-lang.org/rustup/dist/x86_64-unknown-linux-gnu/rustup-init && \
  chmod +x rustup-init && \
  ./rustup-init --default-toolchain nightly --no-modify-path -y && \
  . ${HOME}/.cargo/env && \
  cargo +nightly install just -Z sparse-registry

# For reasons unclear, the PATH environment variable does not get modified by
# the .bashrc when using the entrypoint script. Tried lots of different things.
# Therefore, we manually apply the paths we need.
ENV PATH=$PATH:/home/runner/.local/bin:/home/runner/.cargo/bin
WORKDIR /home/runner/sn_testnet_tool
ENTRYPOINT ["/entrypoint.sh"]
