# This template creates an S3 bucket and a role with access to share with other AWS account ARNS.  By default the current account id (assumed to be your main account) is added to the list of ARNS to able assume the role (even though it is unnecessary, since it has access through another seperate policy) and access the bucket to demonstrate the role, but other account ID's / ARNS can be listed as well.

provider "aws" {
  #  if you haven't installed and configured the aws cli, you will need to provide your aws access key and secret key.
  # in a dev environment these version locks below can be disabled.  in production, they should be locked based on the suggested versions from terraform init.
  version = "~> 3.15.0"
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_canonical_user_id" "current" {}

locals {
  common_tags     = {
    environment  = "prod"
    resourcetier = "main"
    conflictkey  = "main1" 
    # The conflict key defines a name space where duplicate resources in different deployments sharing this name are prevented from occuring.  This is used to prevent a new deployment overwriting an existing resource unless it is destroyed first.
    # examples might be blue, green, dev1, dev2, dev3...dev100.  This allows us to lock deployments on some resources.
    pipelineid   = "0"
    owner        = data.aws_canonical_user_id.current.display_name
    accountid    = data.aws_caller_identity.current.account_id
    terraform    = "true"
    role = "shared bucket"
    region = data.aws_region.current.name
  }
  share_with_arns = concat( [ data.aws_caller_identity.current.account_id ], var.share_with_arns )
  
  vault_map = element( concat( data.vault_generic_secret.vault_map.*.data, list({}) ), 0 )
  bucket_name = var.use_vault && contains( keys(local.vault_map), "value" ) ? lookup( local.vault_map, "value", var.bucket_name) : var.bucket_name
}

# See https://blog.gruntwork.io/how-to-manage-terraform-state-28f5697e68fa for the origin of some of this code.

data "vault_generic_secret" "installers_bucket" { # The name of the bucket is defined in vault  
  count = var.use_vault ? 1 : 0
  path = "/main/aws/installers_bucket"
}

resource "aws_s3_bucket" "shared_bucket" {
  bucket = local.bucket_name
  acl    = "private"

  versioning {
    enabled = false
  }
  # Enable server-side encryption by default
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = merge(
    {"description" = "Used for storing files for reuse accross accounts."},
    local.common_tags,
  )
}

resource "aws_s3_bucket_public_access_block" "backend" { # https://medium.com/dnx-labs/terraform-remote-states-in-s3-d74edd24a2c4
  bucket = aws_s3_bucket.shared_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "shared_bucket_policy" {
  bucket = aws_s3_bucket.shared_bucket.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "s3MultiAccountSharePolicy",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.shared_bucket.arn}",
        "${aws_s3_bucket.shared_bucket.arn}/*"
      ],
      "Principal": {
        "AWS": [
          "${data.aws_caller_identity.current.account_id}"
        ]
      }
    },
    {
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.shared_bucket.arn}",
        "${aws_s3_bucket.shared_bucket.arn}/*"
      ],
      "Principal": {
        "AWS": [
          "${aws_iam_role.multiple_account_assume_role.arn}"
        ]
      }
    },
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "${aws_iam_role.multiple_account_assume_role.arn}"
        ]
      },
      "Action": [
        "s3:PutObject",
        "s3:PutObjectAcl"
      ],
      "Resource": [
        "${aws_s3_bucket.shared_bucket.arn}/*"
      ],
      "Condition": {
          "StringEquals": {
              "s3:x-amz-acl": "bucket-owner-full-control"
          }
      }
    }
  ]
}
POLICY
}

# we create a role that would be used for cross account access to the bucket.

data "aws_iam_policy_document" "multiple_account_assume_role_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = local.share_with_arns
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "multiple_account_assume_role" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.multiple_account_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "multiple_account_assume_role" {
  count = length(local.policy_arns)
  role       = aws_iam_role.multiple_account_assume_role.name
  policy_arn = element(local.policy_arns, count.index)
}

locals {
  policy_arns = [ aws_iam_policy.multiple_account_iam_policy_s3_bucket.arn ] # multiple polices can be attached to the role here.
}

resource "aws_iam_policy" "multiple_account_iam_policy_s3_bucket" {
  name        = "multiple_account_iam_policy_s3_bucket"
  path        = "/"
  description = "Policy for multiple accounts to access s3 bucket"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListAllMyBuckets",
        "s3:GetBucketLocation"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "${aws_s3_bucket.shared_bucket.arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": "${aws_s3_bucket.shared_bucket.arn}/*"
    }
  ]
}
EOF
}

# If a user has restricted permissions the following IAM permissions are required to use the bucket
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Action": "s3:ListBucket",
#       "Resource": "arn:aws:s3:::mybucket"
#     },
#     {
#       "Effect": "Allow",
#       "Action": ["s3:GetObject", "s3:PutObject"],
#       "Resource": "arn:aws:s3:::mybucket/path/to/something"
#     }
#   ]
# 