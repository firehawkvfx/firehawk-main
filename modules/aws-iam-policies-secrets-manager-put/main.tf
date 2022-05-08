terraform {
  required_version = ">= 0.13.5"
}
resource "aws_iam_role_policy" "policy" {
  name   = var.name
  role   = var.iam_role_id
  policy = data.aws_iam_policy_document.policy_doc.json
}
data "aws_kms_alias" "deadline_kms_alias" {
  name = "alias/firehawk/resourcetier/${var.resourcetier}/deadline_cert_kms_key_id"
}
data "aws_secretsmanager_secret" "deadline_cert" {
  name = "/firehawk/resourcetier/${var.resourcetier}/file_deadline_cert_content"
}
data "aws_iam_policy_document" "policy_doc" {
  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:DescribeKey",
    ]
    resources = [data.aws_kms_alias.deadline_kms_alias.target_key_arn]
  }
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:PutSecretValue",
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds"
    ]
    resources = [data.aws_secretsmanager_secret.deadline_cert.arn]
  }
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:ListSecrets"
    ]
    resources = ["*"]
  }
}