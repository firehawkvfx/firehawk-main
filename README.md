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

Ensure you have selected:
`Create a new no-ingress EC2 instance for environment (access via Systems Manager)`
This will create a Cloud 9 instance with no inbound access.

Ensure you add tags:
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

- Create a policy enabling Packer to build images with vault access.  You only need to ensure these policies exist once per resourcetier (dev/green/blue/prod).
```
cd modules/terraform-aws-iam-s3
./generate-plan
terraform apply tfplan
```

- Build Vault and Consul Images
```
cd $TF_VAR_firehawk_path
./build.sh
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
