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
  name = "vault_kms_unseal_key_id"
  type = "SecureString"
}

data "aws_kms_key" "vault" {
  key_id = data.aws_ssm_parameter.vault_kms_unseal
}