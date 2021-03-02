# An example profile and role for an EC2 instance to access vault credentials to be used on something like a packer build instance or other host needing implicit access to vault.

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_canonical_user_id" "current" {}

locals {
  common_tags = {
    environment  = var.environment
    resourcetier = var.resourcetier
    conflictkey  = var.conflictkey
    # The conflict key defines a name space where duplicate resources in different deployments sharing this name are prevented from occuring.  This is used to prevent a new deployment overwriting and existing resource unless it is destroyed first.
    # examples might be blue, green, dev1, dev2, dev3...dev100.  This allows us to lock deployments on some resources.
    pipelineid = var.pipelineid
    owner      = data.aws_canonical_user_id.current.display_name
    accountid  = data.aws_caller_identity.current.account_id
    region     = data.aws_region.current.name
    terraform  = "true"
  }
}

resource "aws_iam_instance_profile" "vault_client_profile" {
  path = "/"
  role = aws_iam_role.vault_client_role.name
  tags = local.common_tags
}

resource "aws_iam_role" "vault_client_role" {
  name        = var.role_name
  assume_role_policy = data.aws_iam_policy_document.vault_client_assume_role.json
  tags = local.common_tags
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
  name   = "set_instance_health_${var.conflictkey}"
  role   = aws_iam_role.vault_client_role.id
  policy = data.aws_iam_policy_document.set_instance_health.json
  tags = local.common_tags
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