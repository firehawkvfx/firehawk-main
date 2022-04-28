# This module generates AWS credentials to read SSM parameters required to retrieve SSH certificates for a client.

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "vault_aws_secret_backend_role" "role" {
  backend         = var.vault_aws_secret_backend_path # vault_aws_secret_backend.aws.path
  name            = var.backend_name
  credential_type = "iam_user"

  policy_document = data.aws_iam_policy_document.read_ssm_paremeters_cert.json
}
data "aws_kms_key" "ssm_key" {
  key_id = "alias/aws/ssm"
}
data "aws_iam_policy_document" "read_ssm_paremeters_cert" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:DescribeParameters"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParametersByPath",
      "ssm:GetParameter",
      "ssm:GetParameters"
    ]
    resources = ["arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/firehawk/resourcetier/${var.resourcetier}/*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt"
    ]
    resources = [data.aws_kms_key.ssm_key.arn]
    # resources = ["arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/${data.aws_kms_key.ssm_key.id}"]
  }
  statement {
    effect = "Allow"
    actions = [
      "sqs:SendMessage",
      "sqs:DeleteMessage",
      "sqs:SendMessageBatch",
      "sqs:GetQueueAttributes"
    ]
    resources = var.sqs_send_arns
  }
  statement {
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage", # when recieving a message it should also be deleted from the queue.
      "sqs:GetQueueAttributes"
    ]
    resources = var.sqs_recieve_arns
  }
}