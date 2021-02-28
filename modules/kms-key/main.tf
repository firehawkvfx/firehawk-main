provider "aws" {
  #  if you haven't installed and configured the aws cli, you will need to provide your aws access key and secret key.
  # in a dev environment these version locks below can be disabled.  in production, they should be locked based on the suggested versions from terraform init.
  version = "~> 3.15.0"
}

resource "random_pet" "env" {
  length = 2
}

resource "aws_kms_key" "vault" {
  description             = "Vault unseal key"
  deletion_window_in_days = 10

  tags = {
    Name = "vault-kms-unseal-${random_pet.env.id}"
  }
}

resource "aws_ssm_parameter" "vault_kms_unseal" {
  name  = "vault_kms_unseal_key_id"
  type  = "SecureString"
  value = aws_kms_key.vault.id
}

data "aws_ssm_parameter" "vault_kms_unseal" {
  depends_on = [aws_ssm_parameter.vault_kms_unseal]
  name = "vault_kms_unseal_key_id"
}

data "aws_kms_key" "vault" {
  key_id = data.aws_ssm_parameter.vault_kms_unseal.value
}