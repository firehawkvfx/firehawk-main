provider "aws" {
  #  if you haven't installed and configured the aws cli, you will need to provide your aws access key and secret key.
  # in a dev environment these version locks below can be disabled.  in production, they should be locked based on the suggested versions from terraform init.
  version = "~> 3.15.0"
}

resource "random_pet" "env" {
  length = 2
}


locals {
  common_tags = {
    environment  = var.environment
    resourcetier = var.resourcetier
    conflictkey  = "${var.resourcetier}" # The conflict key defines a name space where duplicate resources in different deployments sharing this name can be uniquely recognised. In this case, we only use 1 kms key per resource tier to save costs for creating new keys.  Normally we would also include the pipelineid as well in other circumstances.
    pipelineid   = var.pipelineid
    owner        = data.aws_canonical_user_id.current.display_name
    accountid    = data.aws_caller_identity.current.account_id
    terraform    = "true"
  }
}

resource "aws_kms_key" "vault" {
  description             = "Vault unseal key"
  deletion_window_in_days = 10
  tags  = merge(map("Name", "vault-kms-unseal-${random_pet.env.id}"), var.common_tags)
}

resource "aws_ssm_parameter" "vault_kms_unseal" {
  name  = "/firehawk/resourcetier/${var.resourcetier}/vault_kms_unseal_key_id"
  type  = "SecureString"
  value = aws_kms_key.vault.id
  tags  = merge(map("Name", "vault_kms_unseal_key_id"), var.common_tags)
}

data "aws_ssm_parameter" "vault_kms_unseal" {
  depends_on = [aws_ssm_parameter.vault_kms_unseal]
  name = "/firehawk/resourcetier/${var.resourcetier}/vault_kms_unseal_key_id"
}

data "aws_kms_key" "vault" {
  key_id = data.aws_ssm_parameter.vault_kms_unseal.value
}