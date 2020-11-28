# You must be logged into Vault for this module to function. 

provider "vault" {
}

provider "aws" {
  #  if you haven't installed and configured the aws cli, you will need to provide your aws access key and secret key.
  # in a dev environment these version locks below can be disabled.  in production, they should be locked based on the suggested versions from terraform init.
  version = "~> 3.15.0"
}

resource "vault_auth_backend" "example" {
  type = "userpass"
}

resource "vault_policy" "admin_policy" {
  name   = "admins"
  policy = file("policies/admin_policy.hcl")
}

resource "vault_policy" "dev_policy" {
  name   = "dev"
  policy = file("policies/dev_policy.hcl")
}

resource "vault_policy" "prod_policy" {
  name   = "prod"
  policy = file("policies/prod_policy.hcl")
}

resource "vault_policy" "provisioner_policy" {
  name   = "provisioner"
  policy = file("policies/provisioner_policy.hcl")
}

resource "vault_mount" "dev" {
  path        = "dev"
  type        = "kv-v2"
  description = "KV2 Secrets Engine for dev."
}

resource "vault_mount" "prod" {
  path        = "prod"
  type        = "kv-v2"
  description = "KV2 Secrets Engine for prod."
}

module "update-values" { # Init defaults
  source = "./modules/update-values"
  init = var.init
  envtier = var.envtier
  resourcetier = var.resourcetier
  mount_path = var.envtier == "dev" ? vault_mount.dev.path : vault_mount.prod.path
  for_each = local.defaults
  secret_name = each.key
  system_default = each.value
  restore_defaults = var.restore_defaults # defaults will always be updated if the present value matches a present default, but if this var is true, any present user values will be reset always.
}

resource "vault_auth_backend" "aws" {
  type = "aws"
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

module "vault_client_iam" { # the arn of a role will turn into an id when it is created, which may change, so we probably only want to do this once, or the refs in vault will be incorrect.
  source = "../../modules/vault-client-iam-profile"
  role_name = "ProvisionerRole"
}

resource "vault_aws_auth_backend_role" "provisioner" {
  backend                         = vault_auth_backend.aws.path
  role                            = "test-role"
  auth_type                       = "iam"
  # bound_ami_ids                   = ["ami-8c1be5f6"]
  bound_account_ids               = [data.aws_caller_identity.current.account_id]
  # bound_vpc_ids                   = ["vpc-b61106d4"]
  # bound_subnet_ids                = ["vpc-133128f1"]
  # bound_iam_role_arns             = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ProvisionerRole"] # Only instances with this Role ARN May read vault data.
  bound_iam_role_arns             = [ module.vault_client_iam.vault_client_role_arn ] # Only instances with this Role ARN May read vault data.
  # bound_iam_instance_profile_arns = ["arn:aws:iam::123456789012:instance-profile/MyProfile"]
  inferred_entity_type            = "ec2_instance"
  inferred_aws_region             = data.aws_region.current.name
  token_ttl                       = 60
  token_max_ttl                   = 120
  token_policies                  = ["provisioner"]
}

resource "vault_aws_auth_backend_client" "provisioner" {
  backend    = vault_auth_backend.aws.path
  iam_server_id_header_value = "vault.service.consul"
}