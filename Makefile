SHELL := /bin/bash
SN_TESTNET_SSH_KEY_PATH := ~/.ssh/id_rsa
SN_TESTNET_NODE_COUNT := 15
SN_TESTNET_CLIENT_COUNT := 0

alpha:
	rm -rf .terraform
	terraform init
	terraform workspace select alpha
	./up.sh \
		"${SN_TESTNET_SSH_KEY_PATH}" \
		"${SN_TESTNET_NODE_COUNT}" \
		"${SN_TESTNET_NODE_BIN_PATH}" \
		"${SN_TESTNET_NODE_VERSION}" \
		"${SN_TESTNET_CLIENT_COUNT}" \
		"-auto-approve"
	[[ ! -d "~/.safe/prefix_maps" ]] && mkdir -p ~/.safe/prefix_maps
	rm -f ~/.safe/prefix_maps/alpha-prefix-map
	cp alpha-prefix-map ~/.safe/prefix_maps/default

clean-alpha:
	terraform workspace select alpha
	./down.sh "${SN_TESTNET_SSH_KEY_PATH}" "-auto-approve"

beta:
	rm -rf .terraform
	terraform init
	terraform workspace select beta
	./up.sh \
		"${SN_TESTNET_SSH_KEY_PATH}" \
		"${SN_TESTNET_NODE_COUNT}" \
		"${SN_TESTNET_NODE_BIN_PATH}" \
		"${SN_TESTNET_NODE_VERSION}" \
		"${SN_TESTNET_CLIENT_COUNT}" \
		"-auto-approve"
	[[ ! -d "~/.safe/prefix_maps" ]] && mkdir -p ~/.safe/prefix_maps
	rm -f ~/.safe/prefix_maps/beta-prefix-map
	cp beta-prefix-map ~/.safe/prefix_maps/default

clean-beta:
	terraform workspace select beta
	./down.sh "${SN_TESTNET_SSH_KEY_PATH}" "-auto-approve"
