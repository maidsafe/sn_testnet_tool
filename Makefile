SHELL := /bin/bash
SN_TESTNET_SSH_KEY_PATH := ~/.ssh/id_rsa
SN_TESTNET_NO_OF_NODES := 15

alpha:
	rm -rf .terraform
	terraform init
	terraform workspace select alpha
	./up.sh \
		"${SN_TESTNET_SSH_KEY_PATH}" \
		"${SN_TESTNET_NO_OF_NODES}" \
		"${SN_TESTNET_NODE_BIN}" \
		"${SN_TESTNET_NODE_VERSION}" \
		"-auto-approve"
	[[ ! -d "~/.safe/node" ]] && mkdir -p ~/.safe/node
	rm -f ~/.safe/node/node_connection_info.config
	cp alpha-node_connection_info.config ~/.safe/node/node_connection_info.config

clean-alpha:
	terraform workspace select alpha
	./down.sh "${SN_TESTNET_SSH_KEY_PATH}" "-auto-approve"

beta:
	rm -rf .terraform
	terraform init
	terraform workspace select beta
	./up.sh \
		"${SN_TESTNET_SSH_KEY_PATH}" \
		"${SN_TESTNET_NO_OF_NODES}" \
		"${SN_TESTNET_NODE_BIN}" \
		"${SN_TESTNET_NODE_VERSION}" \
		"-auto-approve"
	[[ ! -d "~/.safe/node" ]] && mkdir -p ~/.safe/node
	rm -f ~/.safe/node/node_connection_info.config
	cp beta-node_connection_info.config ~/.safe/node/node_connection_info.config

clean-beta:
	terraform workspace select beta
	./down.sh "${SN_TESTNET_SSH_KEY_PATH}" "-auto-approve"
