include {
  path = find_in_parent_folders()
}

dependencies {
  paths = [
    "../terraform-aws-iam-profile-bastion", 
    "../terraform-aws-iam-profile-deadline-db", 
    "../terraform-aws-iam-profile-openvpn",
    "../terraform-aws-iam-profile-provisioner",  
    "../terraform-aws-iam-profile-vault-client",
    ]
}

skip = true

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
}

inputs = local.common_vars.inputs