# An example profile and role for an EC2 instance to access vault credentials to be used on something like a packer build instance.

resource "aws_iam_instance_profile" "vault_client_profile" {
  path = "/"
  role = aws_iam_role.vault_client_role.name
}

resource "aws_iam_role" "vault_client_role" {
  name        = var.role_name
  # assume_role_policy = data.aws_iam_policy_document.example_instance_role.json
}

# resource "aws_iam_role_policy" "example_instance_role_policy" {
#   name   = "auto-discover-cluster"
#   role   = aws_iam_role.example_instance_role.id
#   policy = data.aws_iam_policy_document.example_instance_role.json
# }

# data "aws_iam_policy_document" "example_instance_role" {
#   statement {
#     effect  = "Allow"
#     actions = ["sts:AssumeRole"]

#     principals {
#       type        = "Service"
#       identifiers = ["ec2.amazonaws.com"]
#     }
#   }
# }

# Adds policies necessary for running consul
module "consul_iam_policies_for_client" {
  source = "github.com/hashicorp/terraform-aws-consul.git//modules/consul-iam-policies?ref=v0.7.7"

  iam_role_id = aws_iam_role.vault_client_role.id
}