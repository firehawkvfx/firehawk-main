provider "aws" {
  #  if you haven't installed and configured the aws cli, you will need to provide your aws access key and secret key.
  # in a dev environment these version locks below can be disabled.  in production, they should be locked based on the suggested versions from terraform init.
  version = "~> 3.15.0"
}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_canonical_user_id" "current" {}

locals {
  common_tags     = {
    environment  = "prod"
    resourcetier = "main"
    conflictkey  = "main1" 
    # The conflict key defines a name space where duplicate resources in different deployments sharing this name are prevented from occuring.  This is used to prevent a new deployment overwriting an existing resource unless it is destroyed first.
    # examples might be blue, green, dev1, dev2, dev3...dev100.  This allows us to lock deployments on some resources.
    pipelineid   = "0"
    owner        = data.aws_canonical_user_id.current.display_name
    accountid    = data.aws_caller_identity.current.account_id
    terraform    = "true"
    role = "terraform remote state"
  }
  bucket_extension = var.bucket_extension
}

resource "vault_auth_backend" "example" {
  type = "userpass"
}

resource "vault_policy" "admin_policy" {
  name   = "admins"
  policy = file("policies/admin_policy.hcl")
}

resource "vault_policy" "developer_policy" {
  name   = "developers"
  policy = file("policies/developer_policy.hcl")
}

resource "vault_policy" "operations_policy" {
  name   = "operations"
  policy = file("policies/operation_policy.hcl")
}

resource "vault_mount" "developers" {
  path        = "developers"
  type        = "kv-v2"
  description = "KV2 Secrets Engine for Developers."
}

resource "vault_mount" "operations" {
  path        = "operations"
  type        = "kv-v2"
  description = "KV2 Secrets Engine for Operations."
}

# data "vault_generic_secret" "deadline_version" {
#   path = "${vault_mount.developers.path}/${local.secret_tier}/config/deadline_version"
# }

locals {
  defaults = tomap( {
    "deadline_version" = {
      description = "The version of the deadline installer.",
      default = "10.1.9.2",
      example_1 = "10.1.9.2",
    },
    "selected_ansible_version" = {
      description = "The version to use for ansible.  Can be 'latest', or a specific version.  due to a bug with pip and ansible we can have pip permissions and authentication issues when not using latest. This is because pip installs the version instead of apt-get when using a specific version instead of latest.  Resolution by using virtualenv will be required to resolve.",
      default = "latest",
      example_1 = "latest",
      example_2 = "2.9.2"
    }
  } )
}

# locals {
#   secret_tier = "dev"
#   deadline_version_system_default = { # New defaults
#     description = "The version of the deadline installer."
#     default = "10.1.9.0"
#     example_1 = "10.1.9.2"
#   }
#   deadline_version_value = { # If a present value is different to a present default, use the value.  Else use the system default.
#     value = contains( keys(data.vault_generic_secret.deadline_version.data), "value" ) && contains( keys(data.vault_generic_secret.deadline_version.data), "default" ) && lookup( data.vault_generic_secret.deadline_version.data, "value", "" ) != lookup( data.vault_generic_secret.deadline_version.data, "default", "") ? lookup( data.vault_generic_secret.deadline_version.data, "value", "") : local.deadline_version_system_default["default"] 
#   }
  
#   deadline_version_result = merge( local.deadline_version_system_default, local.deadline_version_value )
# }

# resource "vault_generic_secret" "deadline_version" {
#   path = "${vault_mount.developers.path}/${local.secret_tier}/config/deadline_version"

#   data_json = jsonencode( local.deadline_version_result )
# }

module "update-values" {
  source = "./modules/update-values"
  mount_path = vault_mount.developers.path
  secret_tier = "dev"
  for_each = local.defaults
  secret_name = each.key
  system_default = each.value
  restore_defaults = var.restore_defaults # defaults will always be updated if the value is already at a default, but if this condition is true, any present user values will be reset always.
}

# resource "vault_generic_secret" "selected_ansible_version" {
#   path = "${vault_mount.developers.path}/${local.secret_tier}/config/selected_ansible_version"

#   data_json = <<EOT
# {
#   "description": "The version to use for ansible.  Can be 'latest', or a specific version.  due to a bug with pip and ansible we can have pip permissions and authentication issues when not using latest. This is because pip installs the version instead of apt-get when using a specific version instead of latest.  Resolution by using virtualenv will be required to resolve.",
#   "default": "latest",
#   "example_1": "latest",
#   "example_2": "2.9.2",
#   "value": "latest"
# }
# EOT
# }

# resource "vault_generic_secret" "syscontrol_gid" {
#   path = "${vault_mount.developers.path}/${local.secret_tier}/config/syscontrol_gid"

#   data_json = <<EOT
# {
#   "description": "The group gid for the syscontrol group",
#   "default": "9003",
#   "example_1": "9003",
#   "value": "9003"
# }
# EOT
# }

# resource "vault_generic_secret" "deployuser_uid" {
#   path = "${vault_mount.developers.path}/${local.secret_tier}/config/deployuser_uid"

#   data_json = <<EOT
# {
#   "description": "The UID of the deployuser for all hosts.  Ansible uses this user connect to provision with.",
#   "default": "9004",
#   "example_1": "9004",
#   "value": "9004"
# }
# EOT
# }