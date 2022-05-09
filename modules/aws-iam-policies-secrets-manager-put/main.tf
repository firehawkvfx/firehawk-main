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
  statement { # see https://medium.com/avmconsulting-blog/best-practice-rules-for-aws-secrets-manager-97caaff6cea5
    effect = "Allow"
    sid = "Allow the use of the CMK"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*"
    ]
    resources = [data.aws_kms_alias.deadline_kms_alias.target_key_arn]
  }
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:PutSecretValue",
      "secretsmanager:UpdateSecret",
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