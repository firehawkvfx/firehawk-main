# An example profile and role for an EC2 instance to access vault credentials to be used on something like a packer build instance.

resource "aws_iam_instance_profile" "vault_client_profile" {
  path = "/"
  role = aws_iam_role.vault_client_role.name
}

resource "aws_iam_role" "vault_client_role" {
  name        = var.role_name
  assume_role_policy = data.aws_iam_policy_document.vault_client_assume_role.json
}

# resource "aws_iam_role_policy" "vault_client_assume_role_policy" {
#   name   = "auto-discover-cluster"
#   role   = aws_iam_role.vault_client_assume_role.id
#   policy = data.aws_iam_policy_document.vault_client_assume_role.json
# }

data "aws_iam_policy_document" "vault_client_assume_role" { 
  # Determines the services able to assume the role.  Any entity assuming this role will be able to authenticate to vault.
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Adds policies necessary for running consul
module "consul_iam_policies_for_client" {
  source = "github.com/hashicorp/terraform-aws-consul.git//modules/consul-iam-policies?ref=v0.7.7"

  iam_role_id = aws_iam_role.vault_client_role.id
}

# allow permision to set instance health.
resource "aws_iam_role_policy" "set_instance_health" {
  name   = "set-instance-health"
  role   = aws_iam_role.vault_client_role.id
  policy = data.aws_iam_policy_document.set_instance_health.json
}

data "aws_iam_policy_document" "set_instance_health" {
  statement {
    effect = "Allow"

    actions = [
      "autoscaling:SetInstanceHealth",
    ]

    resources = ["*"]
  }
}