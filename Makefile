SHELL := /bin/bash
SN_TESTNET_SSH_KEY_PATH := ~/.ssh/id_rsa
SN_TESTNET_NODE_COUNT := 15
SN_TESTNET_CLIENT_COUNT := 0

alpha:
	rm -rf workspace/alpha
	mkdir -p workspace/alpha
	rm -rf .terraform
	terraform init
	terraform workspace select alpha
	./up.sh \
		"${SN_TESTNET_SSH_KEY_PATH}" \
		"${SN_TESTNET_NODE_COUNT}" \
		"${SN_TESTNET_NODE_BIN_PATH}" \
		"${SN_TESTNET_NODE_VERSION}" \
		"${SN_TESTNET_CLIENT_COUNT}" \
		"-auto-approve" \
		"${SN_TESTNET_OTLP_COLLECTOR_ENDPOINT}"
	rm -rf ~/.safe
	mkdir -p ~/.safe/network_contacts
	cp workspace/alpha/network-contacts ~/.safe/network_contacts/default
	cp workspace/alpha/genesis-dbc ~/.safe/genesis_dbc

clean-alpha:
	terraform workspace select alpha
	./down.sh "${SN_TESTNET_SSH_KEY_PATH}" "-auto-approve"

beta:
	rm -rf workspace/beta
	mkdir -p workspace/beta
	rm -rf .terraform
	terraform init
	terraform workspace select beta
	./up.sh \
		"${SN_TESTNET_SSH_KEY_PATH}" \
		"${SN_TESTNET_NODE_COUNT}" \
		"${SN_TESTNET_NODE_BIN_PATH}" \
		"${SN_TESTNET_NODE_VERSION}" \
		"${SN_TESTNET_CLIENT_COUNT}" \
		"-auto-approve" \
		"${SN_TESTNET_OTLP_COLLECTOR_ENDPOINT}"
	rm -rf ~/.safe
	mkdir -p ~/.safe/network_contacts
	cp workspace/beta/network-contacts ~/.safe/network_contacts/default
	cp workspace/beta/genesis-dbc ~/.safe/genesis_dbc

clean-beta:
	terraform workspace select beta
	./down.sh "${SN_TESTNET_SSH_KEY_PATH}" "-auto-approve"
