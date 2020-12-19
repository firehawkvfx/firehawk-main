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

resource "vault_policy" "green_policy" {
  name   = "green"
  policy = file("policies/green_policy.hcl")
}

resource "vault_policy" "blue_policy" {
  name   = "blue"
  policy = file("policies/blue_policy.hcl")
}

resource "vault_policy" "main_policy" {
  name   = "main"
  policy = file("policies/main_policy.hcl")
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

resource "vault_mount" "green" {
  path        = "green"
  type        = "kv-v2"
  description = "KV2 Secrets Engine for green."
}

resource "vault_mount" "blue" {
  path        = "blue"
  type        = "kv-v2"
  description = "KV2 Secrets Engine for blue."
}

resource "vault_mount" "main" {
  path        = "main"
  type        = "kv-v2"
  description = "KV2 Secrets Engine for main."
}

module "update-values-dev" { # Init defaults
  source = "./modules/update-values"
  init = var.init
  resourcetier = "dev" # dev, green, blue, or main
  mount_path = "dev"
  for_each = local.dev
  secret_name = each.key
  system_default = each.value
  restore_defaults = var.restore_defaults # defaults will always be updated if the present value matches a present default, but if this var is true, any present user values will be reset always.
}

module "update-values-green" { # Init defaults
  source = "./modules/update-values"
  init = var.init
  resourcetier = "green" # dev, green, blue, or main
  mount_path = "green"
  for_each = local.green
  secret_name = each.key
  system_default = each.value
  restore_defaults = var.restore_defaults # defaults will always be updated if the present value matches a present default, but if this var is true, any present user values will be reset always.
}

module "update-values-blue" { # Init defaults
  source = "./modules/update-values"
  init = var.init
  resourcetier = "blue" # dev, green, blue, or main
  mount_path = "blue"
  for_each = local.blue
  secret_name = each.key
  system_default = each.value
  restore_defaults = var.restore_defaults # defaults will always be updated if the present value matches a present default, but if this var is true, any present user values will be reset always.
}

module "update-values-main" { # Init defaults
  source = "./modules/update-values"
  init = var.init
  resourcetier = "main" # dev, green, blue, or main
  mount_path = "main"
  for_each = local.main
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
  source = "../../modules/vault-client-iam"
  role_name = "ProvisionerRole"
}

# Once vault is configured below with the provisioner-vault-role, it is possible for any instance with the correct IAM profile to authenticate.
# export VAULT_ADDR=https://vault.service.consul:8200
# vault login -method=aws header_value=vault.service.consul role=provisioner-vault-role

resource "vault_aws_auth_backend_role" "provisioner" {
  backend                         = vault_auth_backend.aws.path
  role                            = "provisioner-vault-role"
  auth_type                       = "iam"
  # bound_ami_ids                   = ["ami-8c1be5f6"]
  bound_account_ids               = [data.aws_caller_identity.current.account_id]
  # bound_vpc_ids                   = ["vpc-b61106d4"]
  # bound_subnet_ids                = ["vpc-133128f1"]
  bound_iam_role_arns             = [ module.vault_client_iam.vault_client_role_arn ] # Only instances with this Role ARN May read vault data.
  # bound_iam_instance_profile_arns = ["arn:aws:iam::123456789012:instance-profile/MyProfile"]
  inferred_entity_type            = "ec2_instance"
  inferred_aws_region             = data.aws_region.current.name
  token_ttl                       = 60
  token_max_ttl                   = 120
  token_policies                  = ["provisioner"]
  # iam_server_id_header_value      = "vault.service.consul" # required to mitigate against replay attacks.
}

resource "vault_aws_auth_backend_client" "provisioner" {
  backend    = vault_auth_backend.aws.path
  iam_server_id_header_value = "vault.service.consul"
}

output "vault_client_role_arn" {
  value = module.vault_client_iam.vault_client_role_arn
}

output "vault_client_profile_arn" {
  value = module.vault_client_iam.vault_client_profile_arn
}

# enable certificates for mongo

resource "vault_mount" "pki" {
  path        = "pki"
  type        = "pki"
  description = "PKI for the ROOT CA"
  default_lease_ttl_seconds = 2073600 # 24 days
  max_lease_ttl_seconds = 315360000 # 10 years
}

# resource "vault_pki_secret_backend" "pki" {
#   path = "pki"
#   default_lease_ttl_seconds = 2073600 # 24 days
#   max_lease_ttl_seconds = 315360000 # 10 years
# }

resource "vault_pki_secret_backend_root_cert" "root" {
  depends_on = [ vault_mount.pki ]

  backend = vault_mount.pki.path

  type = "internal"
  common_name = "Root CA"
  ttl = "315360000"
  format = "pem"
  # private_key_format = "der"
  key_type = "rsa"
  key_bits = 4096
  # exclude_cn_from_sans = true
  # ou = "My OU"
  # organization = "Firehawk VFX"
}

# resource "vault_pki_secret_backend" "pki_int" {
#   path = "pki"
#   default_lease_ttl_seconds = 2073600 # 24 days
#   max_lease_ttl_seconds = 315360000 # 10 years
# }

resource "vault_mount" "pki_int" {
  path        = "pki_int"
  type        = "pki"
  description = "PKI for the ROOT CA"
  default_lease_ttl_seconds = 2073600 # 24 days
  max_lease_ttl_seconds = 315360000 # 10 years
}

resource "vault_pki_secret_backend_intermediate_cert_request" "intermediate" {
  depends_on = [ vault_mount.pki, vault_mount.pki_int ]

  backend = vault_mount.pki_int.path

  type = "internal"
  common_name = "pki-ca-int"
}

resource "vault_pki_secret_backend_root_sign_intermediate" "root" {
  depends_on = [ vault_pki_secret_backend_intermediate_cert_request.intermediate ]

  backend = vault_mount.pki.path

  csr = vault_pki_secret_backend_intermediate_cert_request.intermediate.csr
  common_name = "pki-ca-int"
  exclude_cn_from_sans = true
  # ou = "My OU"
  # organization = "My organization"
}
