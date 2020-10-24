#!/bin/bash
export AWS_DEFAULT_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/\(.*\)[a-z]/\1/')

export TF_VAR_aws_private_key_path="$HOME/.ssh/id_rsa"

public_key_path="$HOME/.ssh/id_rsa.pub"
if [[ ! -f $public_key_path ]] ; then
    echo "File $public_key_path is not there, aborting. Ensure you have initialised a keypair with ssh-keygen"
else
    export TF_VAR_vault_public_key=$(cat $public_key_path)
fi
export TF_VAR_vault_public_key=$(cat $public_key_path)

export TF_VAR_remote_ip_cidr="$(curl http://169.254.169.254/latest/meta-data/public-ipv4)/32"

export TF_VAR_inventory="../secrets/inventory"

mkdir -p $TF_VAR_inventory

if [[ ! -f $TF_VAR_inventory/hosts ]] ; then
    echo "ansible_control ansible_connection=local" >> $TF_VAR_inventory/hosts
fi