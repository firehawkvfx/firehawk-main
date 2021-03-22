include {
  path = find_in_parent_folders()
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  skip= ( lower(get_env("TF_VAR_configure_vault", "false"))=="true" ? "false" : "true" )
}

inputs = local.common_vars.inputs

dependencies {
  paths = [
    "../vault"
    ]
}

skip=local.skip

# To initialise vault values (after logging in with root token):
# TF_VAR_configure_vault=true TF_VAR_init=true terragrunt plan -out="tfplan" && terragrunt apply "tfplan"

# To configure vault
# TF_VAR_configure_vault=true terragrunt plan -out="tfplan" && terragrunt apply "tfplan"