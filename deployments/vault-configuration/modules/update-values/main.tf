# This module will initlise vault values to a default if not present or if already matching an existing default
# This allows us to know if a user has configured to a non default value, and if so, leave it in place.

data "vault_generic_secret" "vault_map" { # Get the map of data at the path
  path = "${var.mount_path}/${local.secret_tier}/config/${var.secret_name}"
}

locals {
  secret_tier = var.secret_tier
  system_default = var.system_default # The system default map will define the value if value is not present, or value matches a preexisting default.
   # If a present value is different to a present default, retain the vault value.  Else use the system default.
  secret_value = contains( keys(data.vault_generic_secret.vault_map.data), "value" ) && contains( keys(data.vault_generic_secret.vault_map.data), "default" ) && lookup( data.vault_generic_secret.vault_map.data, "value", "" ) != lookup( data.vault_generic_secret.vault_map.data, "default", "") ? lookup( data.vault_generic_secret.vault_map.data, "value", "") : local.system_default["default"] 
  secret_map = { "value" = local.secret_value }
  result_map = merge( local.system_default, local.secret_map )
}

resource "vault_generic_secret" "vault_map_output" {
  path = "${var.mount_path}/${local.secret_tier}/config/${var.secret_name}"

  data_json = jsonencode( local.result_map )
}