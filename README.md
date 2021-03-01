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

- Once up, in AWS Management Console | EC2 : Select the instance, and change the instance profile to your `Cloud9CustomAdminRoleFirehawk`

- Ensure you can connect to the IDE through AWS Management Console | Cloud9.

- Once connected, disable "AWS Managed Temporary Credentials" ( Select the Cloud9 Icon in the top left | AWS Settings )
Your instance should now have permission to create and destroy any resource with Terraform.

## Create the Hashicorp Vault deployment

- Clone the repo, and install required binaries and packages.
```
git clone --recurse-submodules https://github.com/firehawkvfx/firehawk-main.git
cd firehawk-main; ./install_packages.sh
```

- Initialise the environment variables and spin up the resources.
```
source ./update_vars.sh
```

- Create TLS Certificates for your vault images
```
cd modules/terraform-aws-vault/modules/private-tls-cert
terraform plan -out=tfplan
terraform apply
```

- Build Vault and Consul Images
```
cd $TF_VAR_firehawk_path
./build.sh
```

- Create KMS Keys to auto unseal the vault


- Initialise the vault:
```
ssh ubuntu@(Vault Private IP)
vault operator init -recovery-shares=1 -recovery-threshold=1
vault login (Root Token)
```

- Store all sensitive output in an encrypted password manager for later use.
