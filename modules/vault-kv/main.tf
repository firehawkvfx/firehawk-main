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
  source           = "./modules/update-values"
  init             = var.init
  resourcetier     = "dev" # dev, green, blue, or main
  mount_path       = "dev"
  for_each         = local.dev
  secret_name      = each.key
  system_default   = each.value
  restore_defaults = var.restore_defaults # defaults will always be updated if the present value matches a present default, but if this var is true, any present user values will be reset always.
}
module "update-values-green" { # Init defaults
  source           = "./modules/update-values"
  init             = var.init
  resourcetier     = "green" # dev, green, blue, or main
  mount_path       = "green"
  for_each         = local.green
  secret_name      = each.key
  system_default   = each.value
  restore_defaults = var.restore_defaults # defaults will always be updated if the present value matches a present default, but if this var is true, any present user values will be reset always.
}
module "update-values-blue" { # Init defaults
  source           = "./modules/update-values"
  init             = var.init
  resourcetier     = "blue" # dev, green, blue, or main
  mount_path       = "blue"
  for_each         = local.blue
  secret_name      = each.key
  system_default   = each.value
  restore_defaults = var.restore_defaults # defaults will always be updated if the present value matches a present default, but if this var is true, any present user values will be reset always.
}
module "update-values-main" { # Init defaults
  source           = "./modules/update-values"
  init             = var.init
  resourcetier     = "main" # dev, green, blue, or main
  mount_path       = "main"
  for_each         = local.main
  secret_name      = each.key
  system_default   = each.value
  restore_defaults = var.restore_defaults # defaults will always be updated if the present value matches a present default, but if this var is true, any present user values will be reset always.
}