#!/bin/bash

# Build all required amis.
set -e # Exit on error

# Raise error if var isn't defined.
if [[ -z "$TF_VAR_firehawk_path" ]]; then
    exit_if_error 1 "TF_VAR_firehawk_path not defined. You need to source ./update_vars.sh"
fi

$TF_VAR_firehawk_path/modules/terraform-aws-bastion/modules/bastion-ami/base-ami/build.sh
$TF_VAR_firehawk_path/modules/terraform-aws-bastion/modules/bastion-ami/build.sh
$TF_VAR_firehawk_path/modules/terraform-aws-vault-client/modules/vault-client-ami/base-ami/build.sh
$TF_VAR_firehawk_path/modules/terraform-aws-vault-client/modules/vault-client-ami/build.sh
$TF_VAR_firehawk_path/modules/terraform-aws-vpn/modules/openvpn-server-ami/base-ami/build.sh
$TF_VAR_firehawk_path/modules/terraform-aws-vpn/modules/openvpn-server-ami/build.sh

echo "...Build complete.  When your Consul TLS certificates expire, these images will need to be rebuild with new certificates."