# This module generates AWS credentials to read SSM parameters required to retrieve SSH certificates for a client.

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "vault_aws_secret_backend" "aws" {
}

resource "vault_aws_secret_backend_role" "role" {
  backend = vault_aws_secret_backend.aws.path
  name    = "aws-creds-ssm-parameters-ssh-certs"
  credential_type = "iam_user"

  policy_document = data.aws_iam_policy_document.read_ssm_paremeters_cert.json
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
      "ssm:GetParameters"
    ]
    resources = ["arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/firehawk/resourcetier/${var.resourcetier}/*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "sqs:SendMessage",
      "sqs:SendMessageBatch"
    ]
    resources = var.sqs_send_arns
  }
  statement {
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage" # when recieving a message it should also be deleted from the queue.
    ]
    resources = var.sqs_recieve_arns
  }
}