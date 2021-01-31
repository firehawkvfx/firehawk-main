### This role and profile allows instances access to S3 buckets to aquire and push back downloaded softwre to provision with.  It also has prerequisites for consul and vault access.

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_canonical_user_id" "current" {}

locals {
  common_tags     = {
    resourcetier = var.resourcetier
    conflictkey  = "${var.resourcetier}_${var.pipelineid}"
    # The conflict key defines a name space where duplicate resources in different deployments sharing this name are prevented from occuring.  This is used to prevent a new deployment overwriting and existing resource unless it is destroyed first.
    # examples might be blue, green, dev1, dev2, dev3...dev100.  This allows us to lock deployments on some resources.
    pipelineid   = var.pipelineid
    owner        = data.aws_canonical_user_id.current.display_name
    accountid    = data.aws_caller_identity.current.account_id
    terraform    = "true"
    region = data.aws_region.current.name
  }
}

resource "aws_iam_role" "provisioner_instance_role" {
  name = "provisioner_instance_role_pipeid${lookup(local.common_tags, "pipelineid", "0")}"
  assume_role_policy = data.aws_iam_policy_document.provisioner_instance_assume_role.json
  tags = local.common_tags
}

data "aws_iam_policy_document" "provisioner_instance_assume_role" { # Determines the services able to assume the role.  Any entity assuming this role will be able to authenticate to vault.
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

#     "Principal": { 
#   "AWS": [
#     "arn:aws:iam::123456789012:root",
#     "999999999999"
#   ]
# }

  }
}

# resource "aws_iam_role_policy_attachment" "AmazonS3FullAccess" {
#   role       = aws_iam_role.provisioner_instance_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
# }

# to limit access to a specific bucket, see here - https://aws.amazon.com/blogs/security/writing-iam-policies-how-to-grant-access-to-an-amazon-s3-bucket/
resource "aws_iam_role_policy" "s3_read_write" {
  name = "S3ReadWrite"
  role = aws_iam_role.provisioner_instance_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetBucketLocation",
        "s3:ListAllMyBuckets"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": ["arn:aws:s3:::*"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ],
      "Resource": ["arn:aws:s3:::*"]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "get_caller_identity" {
  name = "STSGetCallerIdentity"
  role = aws_iam_role.provisioner_instance_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sts:GetCallerIdentity"
      ],
      "Resource": ["*"]
    }
  ]
}
EOF
}

# Adds policies necessary for running consul
module "consul_iam_policies_for_client" {
  source = "github.com/hashicorp/terraform-aws-consul.git//modules/consul-iam-policies?ref=v0.7.7"

  iam_role_id = aws_iam_role.provisioner_instance_role.id
}

resource "aws_iam_instance_profile" "provisioner_instance_profile" {
  name = aws_iam_role.provisioner_instance_role.name
  role = aws_iam_role.provisioner_instance_role.name
}