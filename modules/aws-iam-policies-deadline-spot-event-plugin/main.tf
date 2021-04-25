terraform {
  required_version = ">= 0.13.5"
}

resource "aws_iam_role_policy" "s3_read_write" {
  name   = var.name
  role   = var.iam_role_id
  policy = data.aws_iam_policy_document.s3_read_write.json
}

data "aws_iam_policy_document" "s3_read_write" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListAllMyBuckets"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = ["arn:aws:s3:::*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]
    resources = ["arn:aws:s3:::*"]
  }
}