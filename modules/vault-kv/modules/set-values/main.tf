# This module will set values to a map

locals {
  path = "${var.mount_path}/${var.secret_name}"
}

data "vault_generic_secret" "vault_map" { # Get the map of data at the path
  count = 1
  path  = local.path
}

resource "vault_generic_secret" "vault_map_output" {
  count     = 1
  path      = local.path
  data_json = jsonencode(var.system_default)
}