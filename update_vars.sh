#!/bin/bash

to_abs_path() {
  python -c "import os; print(os.path.abspath('$1'))"
}

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )" # The directory of this script

# Instance and vpc data
export TF_VAR_deployer_ip_cidr="$(curl http://169.254.169.254/latest/meta-data/public-ipv4)/32" # Initially there will be no remote ip onsite, so we use the cloud 9 ip.
export TF_VAR_remote_cloud_public_ip_cidr="$(curl http://169.254.169.254/latest/meta-data/public-ipv4)/32" # The cloud 9 IP to provision with.
export TF_VAR_remote_cloud_private_ip_cidr="$(curl http://169.254.169.254/latest/meta-data/local-ipv4)/32"
macid=$(curl http://169.254.169.254/latest/meta-data/network/interfaces/macs/)
export TF_VAR_vpc_id_main_cloud9=$(curl http://169.254.169.254/latest/meta-data/network/interfaces/macs/${macid}/vpc-id) # Aquire the cloud 9 instance's VPC ID to peer with Main VPC
export TF_VAR_instance_id_main_cloud9=$(curl http://169.254.169.254/latest/meta-data/instance-id)

# test aquiring the resourcetier from the instance tag.
aws ec2 describe-tags --filters Name=resource-id,Values=$TF_VAR_instance_id_main_cloud9 --out=json|jq '.Tags[]| select(.Key == "resourcetier")|.Value'

export TF_VAR_resourcetier="main" # Can be dev,green,blue,main
export PKR_VAR_resourcetier="$TF_VAR_resourcetier"
export TF_VAR_pipelineid="0" # Uniquely name and tag the resources produced by a CI pipeline
export TF_VAR_conflictkey="${TF_VAR_resourcetier}${TF_VAR_pipelineid}" # The conflict key is a unique identifier for a deployment.
if [[ "$TF_VAR_resourcetier"=="dev" ]]; then
  export TF_VAR_environment="dev"
else
  export TF_VAR_environment="prod"
fi
export TF_VAR_firehawk_path=$SCRIPTDIR
export AWS_DEFAULT_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/\(.*\)[a-z]/\1/')
export PKR_VAR_aws_region="$AWS_DEFAULT_REGION"
export TF_VAR_aws_internal_domain=$AWS_DEFAULT_REGION.compute.internal # used for FQDN resolution
export PKR_VAR_aws_internal_domain=$AWS_DEFAULT_REGION.compute.internal # used for FQDN resolution
export TF_VAR_aws_external_domain=$AWS_DEFAULT_REGION.compute.amazonaws.com

# Packer Vars
if [[ -f "$SCRIPTDIR/modules/terraform-aws-vault/examples/vault-consul-ami/manifest.json" ]]; then
    export PKR_VAR_vault_consul_ami="$(jq -r '.builds[] | select(.name == "ubuntu18-ami") | .artifact_id' $SCRIPTDIR/modules/terraform-aws-vault/examples/vault-consul-ami/manifest.json | tail -1 | cut -d ":" -f2)"
    echo "Found vault_consul_ami in manifest: PKR_VAR_vault_consul_ami=$PKR_VAR_vault_consul_ami"
    export TF_VAR_vault_consul_ami_id=$PKR_VAR_vault_consul_ami
fi
export PACKER_LOG=1
export PACKER_LOG_PATH="packerlog.log"

# Terraform Vars
export TF_VAR_general_use_ssh_key="$HOME/.ssh/id_rsa" # For debugging deployment of most resources- not for production use.
export TF_VAR_aws_private_key_path="$TF_VAR_general_use_ssh_key"
public_key_path="$HOME/.ssh/id_rsa.pub"
if [[ ! -f $public_key_path ]] ; then
    echo "File $public_key_path is not there, aborting. Ensure you have initialised a keypair with ssh-keygen"
    exit 1
fi
export TF_VAR_vault_public_key=$(cat $public_key_path)

export TF_VAR_log_dir="$SCRIPTDIR/tmp/log"; mkdir -p $TF_VAR_log_dir

export VAULT_ADDR=https://vault.service.consul:8200 # verify dns before login with: dig vault.service.consul
export consul_cluster_tag_key="consul-servers" # These tags are used when new hosts join a consul cluster. 
export consul_cluster_tag_value="consul-$TF_VAR_resourcetier"
export TF_VAR_consul_cluster_tag_key="$consul_cluster_tag_key"
export PKR_VAR_consul_cluster_tag_key="$consul_cluster_tag_key"
export TF_VAR_consul_cluster_name="$consul_cluster_tag_value"
export PKR_VAR_consul_cluster_tag_value="$consul_cluster_tag_value"

aws ssm get-parameters --names \
    "/firehawk/conflictkey/${TF_VAR_conflictkey}/onsite_public_ip" \
    "/firehawk/conflictkey/${TF_VAR_conflictkey}/onsite_private_subnet_cidr" \
    "/firehawk/conflictkey/${TF_VAR_conflictkey}/global_bucket_extension"

# export TF_VAR_onsite_public_ip_cidr="$TF_VAR_onsite_public_ip/32"
# export TF_VAR_bucket_extension="${TF_VAR_resourcetier}.${TF_VAR_global_bucket_extension}" # This is primarily used for terraform state. TODO:set this to main.