### This role and profile allows instances access to S3 buckets to aquire and push back downloaded softwre to provision with.

locals {
  common_tags     = {
    environment  = "prod"
    resourcetier = var.resourcetier
    conflictkey  = "${var.resourcetier}_${var.pipelineid}"
    # The conflict key defines a name space where duplicate resources in different deployments sharing this name are prevented from occuring.  This is used to prevent a new deployment overwriting and existing resource unless it is destroyed first.
    # examples might be blue, green, dev1, dev2, dev3...dev100.  This allows us to lock deployments on some resources.
    pipelineid   = "${var.pipelineid}"
    owner        = data.aws_canonical_user_id.current.display_name
    accountid    = data.aws_caller_identity.current.account_id
    terraform    = "true"
  }
}


resource "aws_iam_role" "provisioner_instance_role" {
  name = "provisioner_instance_role_pipeid${lookup(local.common_tags, "pipelineid", "0")}"
  tags = local.common_tags
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
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

resource "aws_iam_instance_profile" "provisioner_instance_profile" {
  name = aws_iam_role.provisioner_instance_role.name
  role = aws_iam_role.provisioner_instance_role.name
  tags = local.common_tags
}