#!/bin/bash
export AWS_DEFAULT_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/\(.*\)[a-z]/\1/')

public_key_path="$HOME/.ssh/id_rsa.pub"
if [[ ! -f $public_key_path ]] ; then
    echo "File $public_key_path is not there, aborting. Ensure you have initialised a keypair with ssh-keygen"
else
    export TF_VAR_vault_public_key=$(cat $public_key_path)
fi
export TF_VAR_vault_public_key=$(cat $public_key_path)