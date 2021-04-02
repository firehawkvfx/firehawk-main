# This module will initialise vault values to a default if not already present.  If the value already mathes an existing default, and the new default changes, it will also be updated.
# This allows us to know if a user has configured to a non default value, and if so, preserve the users value.

locals {
  path = "${var.mount_path}/${var.secret_name}"
}

resource "null_resource" "init_secret" { # init a secret if empty
  triggers = {
    always_run = timestamp() # Always run this since we dont know if this is a new vault and an old state file.  This could be better.  perhaps track an init var in the vault?
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      echo "Init secret"
      vault kv put -cas=0 "${local.path}" value="" || echo "Value is already initialised / non-zero exit code"
EOT
  }
}