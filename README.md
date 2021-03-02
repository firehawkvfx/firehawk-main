# Firehawk-Main
The Firehawk Main VPC (WIP) deploys Hashicorp Vault into a private VPC with auto unsealing.

This deployment uses Cloud 9 to simplify management of AWS Secret Keys.  You will need to create a custom profile to allow the cloud 9 instance permission to create these resources with Terraform.  
## Policies

- In cloudformation run these templates to init policies and defaults:
  - modules/cloudformation-cloud9-vault-iam/cloudformation_devadmin_policies.yaml
  - modules/cloudformation-cloud9-vault-iam/cloudformation_cloud9_policies.yaml
  - modules/cloudformation-cloud9-vault-iam/cloudformation_ssm_parameters_firehawk.yaml

## Creating The Cloud9 Environment

- In AWS Management Console | Cloud9: Select Create Environment

- Ensure you have selected:
`Create a new no-ingress EC2 instance for environment (access via Systems Manager)`
This will create a Cloud 9 instance with no inbound access.

- Ensure the EBS volume size is 20GB.  If you need to expand the volume more later you can use firehawk-main/scripts/resize.sh

- Ensure the instance type is the recommended type for production (m5.large)

- Ensure you add tags:
```
resourcetier=main
```
The tag will define the environment in the shell.

- Once up, in AWS Management Console | EC2 : Select the instance, and change the instance profile to your `Cloud9CustomAdminRoleFirehawk`

- Ensure you can connect to the IDE through AWS Management Console | Cloud9.

- Once connected, disable "AWS Managed Temporary Credentials" ( Select the Cloud9 Icon in the top left | AWS Settings )
Your instance should now have permission to create and destroy any resource with Terraform.

## Create the Hashicorp Vault deployment

- In the cloud 9 instance, generate an ssh keypair at the deault path and with no password.
```
ssh-keygen
```

- Copy the output of your public key
```
cat ~/.ssh/id_rsa.pub
```

- Paste it into the AWS Management Console | Key Pairs | Import Key Pair.  Name the keypair 'deployuser-main' (Or replace main with the resource tier you are using to deploy into)

- Clone the repo, and install required binaries and packages.
```
git clone --recurse-submodules https://github.com/firehawkvfx/firehawk-main.git
cd firehawk-main; ./install_packages.sh
```

- Initialise the environment variables and spin up the resources.
```
source ./update_vars.sh
```

- Setup an S3 bucket for terraform remote state (Only do this once per resourcetier dev/green/blue/main)
```
cd modules/terraform-s3-bucket-remote-backend
./generate-plan
terraform apply tfplan
```

- Setup an S3 bucket for vault. (Only do this once per resourcetier dev/green/blue/main)
```
cd modules/terraform-s3-bucket-vault-backend
./generate-plan
terraform apply tfplan
```

- Create TLS Certificates for your Vault images
```
cd modules/terraform-aws-vault/modules/private-tls-cert
terraform plan -out=tfplan
terraform apply tfplan
```

- Install Consul and Vault client
```
cd modules/vault
./install-consul-vault-client --vault-module-version v0.13.11  --vault-version 1.5.5 --consul-module-version v0.8.0 --consul-version 1.8.4 --build amazonlinux2 --cert-file-path /home/ec2-user/.ssh/tls/ca.crt.pem
```
## Build images for the bastion, internal vault client, and vpn server

- Build Vault and Consul Images
```
cd $TF_VAR_firehawk_path
./build.sh
```

For each client instance we build a base AMI to run os updates (you only need to do this infrequently).  Then we build the complete AMI from the base AMI to speed up subsequent builds (and provide a better foundation from ever changing software updates).

- Run this script to automate all subsequent builds.
```
scripts/build_vault_clients.sh
```
- Check that you have images for the bastion, vault client, and vpn server in you AWS Management Console | Ami's.  If any are missing you may wish to try running the contents of the script manually.


- Create a policy enabling Packer to build images with vault access.  You only need to ensure these policies exist once per resourcetier (dev/green/blue/prod). These policies are not required to build images in the main account, but may be used to build images for rendering.
```
cd modules/terraform-aws-iam-s3
./generate-plan
terraform apply tfplan
```

- Create KMS Keys to auto unseal the vault
```
cd modules/kms-key
./generate-plan
terraform apply tfplan
```

- Create a VPC for Vault
```
cd modules/vpc
./generate-plan
terraform apply tfplan
```

- Enable peering between vault vpc and current Cloud 9 vpc
```
cd modules/terraform-aws-vpc-main-cloud9-peering
./generate-plan
terraform apply tfplan
```

- Deploy Vault
```
cd $TF_VAR_firehawk_path
./wake
```

- Initialise the vault:
```
ssh ubuntu@(Vault Private IP)
vault operator init -recovery-shares=1 -recovery-threshold=1
vault login (Root Token)
```

- Store all sensitive output in an encrypted password manager for later use.

- exit the vault instance, and ensure you are joined to the consul cluster in the cloud9 instance.
```
sudo /opt/consul/bin/run-consul --client --cluster-tag-key "$${consul_cluster_tag_key}" --cluster-tag-value "$${consul_cluster_tag_value}"
consul catalog services
```
This should show 2 services: consul and vault.

- login to vault on your current instance (using the root token when prompted).  This is the first and only time you will use your root token:
```
vault login
```

- Configure vault with firehawk defaults.
```
cd modules/vault-configuration
./generate-plan-init
terraform apply "tfplan"
```
- Now you can create an admin token
```
vault token create -policy=admins
```

- And login with the new admin token.
```
vault login
```

- Now ensure updates to the vault config will work with your admin token. 
```
terraform apply "tfplan"
./generate-plan
terraform apply "tfplan"
```

Congratulations!  You now have a fully configured vault.

- Add known hosts certificate, sign your cloud9 host Key, and sign your host as an SSH Client to other hosts.
```
./sign-host-key/known_hosts.sh
./sign-host-key/sign_host_key.sh
./sign-ssh-key/sign_ssh_key.sh 
```

The remote host you intend to run the vpn on will need to do the same.
- In the cloud9 file browser, click the cog to show the home dir.
- Create a new folder in /home/ec2-user/.ssh named something like 'remote_host' or the machine name.
- In a file browser on the remote host, ensure you have generated an rsa public key, and drag the public key into this folder in the web browser.
- 

All hosts now have the capability for authenticated SSH with certificates!  The default time to live (TTL) on SSH client certificates is one month, at which point you can just run this step again.

