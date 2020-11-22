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

module "update-values" {
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