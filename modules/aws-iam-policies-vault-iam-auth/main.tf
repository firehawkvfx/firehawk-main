# These policies are required for the IAM role based authentication method with vault.

terraform {
  required_version = ">= 0.13.5"
}

resource "aws_iam_role_policy" "vault_iam_auth" {
  name   = var.name
  role   = var.iam_role_id
  policy = data.aws_iam_policy_document.vault_iam_auth.json
}

data "aws_iam_policy_document" "vault_iam_auth" {
  statement {
    effect = "Allow"
    actions = [
        "ec2:DescribeInstances",
        "iam:GetInstanceProfile",
        "iam:GetUser",
        "iam:GetRole"
    ]
    resources = ["*"]
  }
  # statement { # This block is only required for cross account access
  #   effect = "Allow"
  #   actions = [
  #     "sts:AssumeRole"
  #   ]
  #   resources = ["arn:aws:iam::<AccountId>:role/<VaultRole>"]
  # }
  statement {
    sid = "ManageOwnAccessKeys"
    effect = "Allow"
    actions = [
        "iam:CreateAccessKey",
        "iam:DeleteAccessKey",
        "iam:GetAccessKeyLastUsed",
        "iam:GetUser",
        "iam:ListAccessKeys",
        "iam:UpdateAccessKey"
    ]
    resources = ["arn:aws:iam::*:user/${aws:username}"]
  }
}