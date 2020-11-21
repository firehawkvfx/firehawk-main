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

locals {
  secret_tier = "dev"
}

resource "vault_generic_secret" "deadline_version" {
  path = "${vault_mount.developers.path}/${local.secret_tier}/config/deadline_version/value"

  data_json = <<EOT
{
  "value": "10.1.9.2"
}
EOT
}

resource "vault_generic_secret" "deadline_version_metadata" {
  path = "${vault_mount.developers.path}/${local.secret_tier}/config/deadline_version/metadata"

  data_json = <<EOT
{
  "description": "The version of the deadline installer.",
  "default": "10.1.9.2",
  "example_1": "10.1.9.2"
}
EOT
}

resource "vault_generic_secret" "selected_ansible_version" {
  path = "${vault_mount.developers.path}/${local.secret_tier}/config/selected_ansible_version"

  data_json = <<EOT
{
  "description": "The version to use for ansible.  Can be 'latest', or a specific version.  due to a bug with pip and ansible we can have pip permissions and authentication issues when not using latest. This is because pip installs the version instead of apt-get when using a specific version instead of latest.  Resolution by using virtualenv will be required to resolve.",
  "default": "latest",
  "example_1": "latest",
  "example_2": "2.9.2",
  "value": "latest"
}
EOT
}

resource "vault_generic_secret" "syscontrol_gid" {
  path = "${vault_mount.developers.path}/${local.secret_tier}/config/syscontrol_gid"

  data_json = <<EOT
{
  "description": "The group gid for the syscontrol group",
  "default": "9003",
  "example_1": "9003",
  "value": "9003"
}
EOT
}

resource "vault_generic_secret" "deployuser_uid" {
  path = "${vault_mount.developers.path}/${local.secret_tier}/config/deployuser_uid"

  data_json = <<EOT
{
  "description": "The UID of the deployuser for all hosts.  Ansible uses this user connect to provision with.",
  "default": "9004",
  "example_1": "9004",
  "value": "9004"
}
EOT
}