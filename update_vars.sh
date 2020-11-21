#!/bin/bash

to_abs_path() {
  python -c "import os; print(os.path.abspath('$1'))"
}

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )" # The directory of this script

export AWS_DEFAULT_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/\(.*\)[a-z]/\1/')

# Packer Vars
export PKR_VAR_aws_region="$AWS_DEFAULT_REGION"
if [[ -f "$SCRIPTDIR/modules/terraform-aws-vault/examples/bastion-ami/manifest.json" ]]; then
    export PKR_VAR_bastion_centos7_ami="$(jq -r '.builds[] | select(.name == "centos7-ami") | .artifact_id' $SCRIPTDIR/modules/terraform-aws-vault/examples/bastion-ami/manifest.json | tail -1 | cut -d ":" -f2)"
    echo "Found bastion_centos7_ami in manifest: PKR_VAR_bastion_centos7_ami=$PKR_VAR_bastion_centos7_ami"
    export TF_VAR_bastion_centos7_ami=$PKR_VAR_bastion_centos7_ami
    export TF_VAR_bastion_ami_id=$TF_VAR_bastion_centos7_ami
fi
if [[ -f "$SCRIPTDIR/modules/terraform-aws-vault/examples/nice-dcv-ami/manifest.json" ]]; then
    export PKR_VAR_bastion_amazonlinux2_nicedcv_nvidia_ami="$(jq -r '.builds[] | select(.name == "amazonlinux2-nicedcv-nvidia-ami") | .artifact_id' $SCRIPTDIR/modules/terraform-aws-vault/examples/nice-dcv-ami/manifest.json | tail -1 | cut -d ":" -f2)"
    echo "Found bastion_amazonlinux2_nicedcv_nvidia_ami in manifest: PKR_VAR_bastion_amazonlinux2_nicedcv_nvidia_ami=$PKR_VAR_bastion_amazonlinux2_nicedcv_nvidia_ami"
    export TF_VAR_bastion_amazonlinux2_nicedcv_nvidia_ami=$PKR_VAR_bastion_amazonlinux2_nicedcv_nvidia_ami
    export TF_VAR_bastion_graphical_ami_id=$TF_VAR_bastion_amazonlinux2_nicedcv_nvidia_ami
    # export TF_VAR_bastion_graphical_ami_id="ami-005e5d06689d9e25b" # Temporary test with amazon linux ami
fi
if [[ -f "$SCRIPTDIR/modules/terraform-aws-vault/examples/vault-consul-ami/manifest.json" ]]; then
    export PKR_VAR_vault_consul_ami="$(jq -r '.builds[] | select(.name == "ubuntu18-ami") | .artifact_id' $SCRIPTDIR/modules/terraform-aws-vault/examples/vault-consul-ami/manifest.json | tail -1 | cut -d ":" -f2)"
    echo "Found vault_consul_ami in manifest: PKR_VAR_vault_consul_ami=$PKR_VAR_vault_consul_ami"
    export TF_VAR_vault_consul_ami_id=$PKR_VAR_vault_consul_ami
fi
export PACKER_LOG=1
export PACKER_LOG_PATH="packerlog.log"

# Terraform Vars

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
export TF_VAR_inventory="$(to_abs_path $SCRIPTDIR/../secrets/inventory)"
mkdir -p $TF_VAR_inventory
export TF_VAR_firehawk_path=$PWD
export TF_VAR_log_dir="$PWD/tmp/log"
mkdir -p $TF_VAR_log_dir
if [[ ! -f $TF_VAR_inventory/hosts ]] ; then
    echo "ansible_control ansible_connection=local" >> $TF_VAR_inventory/hosts
fi
macid=$(curl http://169.254.169.254/latest/meta-data/network/interfaces/macs/)
export TF_VAR_vpc_id_main_cloud9=$(curl http://169.254.169.254/latest/meta-data/network/interfaces/macs/${macid}/vpc-id)
export TF_VAR_instance_id_main_cloud9=$(curl http://169.254.169.254/latest/meta-data/instance-id)

export VAULT_ADDR=https://vault.service.consul:8200 # verify dns before login with: dig vault.service.consul

source $SCRIPTDIR/../secrets/secret_vars.sh

echo "After deployment, ssh into the vault and init with: vault operator init -recovery-shares=1 -recovery-threshold=1"
echo "Store the initial root token in a password manager (encrypted)."