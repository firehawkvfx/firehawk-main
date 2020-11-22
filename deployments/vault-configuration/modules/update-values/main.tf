# This module will initlise vault values to a default if not present or if already matching an existing default
# This allows us to know if a user has configured to a non default value, and if so, leave it in place.

locals {
  path = "${var.mount_path}/${var.secret_tier}/config/${var.secret_name}"
}

resource "null_resource" "init_secret" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      vault kv put -cas=0 "${local.path}" value=""
EOT
  }
}

data "vault_generic_secret" "vault_map" { # Get the map of data at the path
  depends_on = [null_resource.init_secret]
  path = local.path
}

locals {
  system_default = var.system_default # The system default map will define the value if value is not present, or value matches a preexisting default.
   # If a present value is different to a present default, retain the vault value.  Else use the system default.
  secret_value = contains( keys(data.vault_generic_secret.vault_map.data), "value" ) && contains( keys(data.vault_generic_secret.vault_map.data), "default" ) && lookup( data.vault_generic_secret.vault_map.data, "value", "" ) != lookup( data.vault_generic_secret.vault_map.data, "default", "") ? lookup( data.vault_generic_secret.vault_map.data, "value", "") : local.system_default["default"] 
  secret_map = var.restore_defaults ? tomap( {"value" = local.system_default["default"] } ) : tomap( {"value" = local.secret_value } )
  result_map = merge( local.system_default, local.secret_map )
}

resource "vault_generic_secret" "vault_map_output" {
  path = local.path

  data_json = jsonencode( local.result_map )
}