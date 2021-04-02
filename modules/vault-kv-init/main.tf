resource "vault_mount" "resourcetier" {
  path        = var.resourcetier
  type        = "kv-v2"
  description = "KV2 Secrets Engine for dev."
}
module "update-values-resourcetier" { # Init defaults
  source           = "./modules/update-values"
  # init             = true
  resourcetier     = var.resourcetier # dev, green, blue, or main
  mount_path       = var.resourcetier
  for_each         = local.dev
  secret_name      = each.key
  system_default   = each.value
  restore_defaults = var.restore_defaults # defaults will always be updated if the present value matches a present default, but if this var is true, any present user values will be reset always.
}