terraform {
  # This module is now only being tested with Terraform 0.13.x. However, to make upgrading easier, we are setting
  # 0.12.26 as the minimum version, as that version added support for required_providers with source URLs, making it
  # forwards compatible with 0.13.x code.
  required_version = ">= 0.13.5"
}

resource "aws_iam_role_policy" "get_caller_identity" {
  name = var.name
  role = var.iam_role_id
  policy = data.aws_iam_policy_document.get_caller_identity.json
}

data "aws_iam_policy_document" "get_caller_identity" {
  statement {
    effect = "Allow"
    actions = [
      "sts:GetCallerIdentity",
    ]
    resources = ["*"]
  }
}