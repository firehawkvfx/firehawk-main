#!/bin/bash

to_abs_path() {
  python -c "import os; print(os.path.abspath('$1'))"
}

export AWS_DEFAULT_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/\(.*\)[a-z]/\1/')
export PKR_VAR_aws_region="$AWS_DEFAULT_REGION"

if [[ -f "modules/terraform-aws-vault/examples/bastion-ami/manifest.json" ]]; then
    export PKR_VAR_bastion_centos7_ami="$(jq -r '.builds[] | select(.name == "centos7-ami") | .artifact_id' modules/terraform-aws-vault/examples/bastion-ami/manifest.json | cut -d ":" -f2)"
    echo "Found bastion_cento7_ami in manifest: PKR_VAR_bastion_centos7_ami=$PKR_VAR_bastion_centos7_ami"
fi

export TF_VAR_aws_private_key_path="$HOME/.ssh/id_rsa"

export TF_VAR_general_use_ssh_key="$TF_VAR_aws_private_key_path" # TF_VAR_general_use_ssh_key is for onsite resources.  In some scenarios the ssh key for onsite may be different to the ssh key used for cloud resources.

public_key_path="$HOME/.ssh/id_rsa.pub"

if [[ ! -f $public_key_path ]] ; then
    echo "File $public_key_path is not there, aborting. Ensure you have initialised a keypair with ssh-keygen"
else
    export TF_VAR_vault_public_key=$(cat $public_key_path)
fi

export TF_VAR_vault_public_key=$(cat $public_key_path)

export TF_VAR_remote_ip_cidr="$(curl http://169.254.169.254/latest/meta-data/public-ipv4)/32"

export TF_VAR_inventory="$(to_abs_path ../secrets/inventory)"
mkdir -p $TF_VAR_inventory

export TF_VAR_firehawk_path=$PWD

export TF_VAR_log_dir="$PWD/tmp/log"
mkdir -p $TF_VAR_log_dir

if [[ ! -f $TF_VAR_inventory/hosts ]] ; then
    echo "ansible_control ansible_connection=local" >> $TF_VAR_inventory/hosts
fi

export TF_VAR_bucket_extension='firehawkvfx.com'

export PACKER_LOG=1
export PACKER_LOG_PATH="packerlog.log"

echo "Ensure you specify your own ami id inline. eg: terraform apply -var 'ami_id=ami-12345678910'"
echo "After deployment, ssh into the vault and init with: vault operator init -recovery-shares=1 -recovery-threshold=1"
echo "Store the initial root token in a password manager (encrypted)."