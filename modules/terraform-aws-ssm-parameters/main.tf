# This initialises AWS SSM parameters required for a deployment.  Provided you have a static IP, this will only need to be performed once.  If your IP changes you may need to update the parameter and subsequent terraform runs frequently.

provider "aws" {
  #  if you haven't installed and configured the aws cli, you will need to provide your aws access key and secret key.
  # in a dev environment these version locks below can be disabled.  in production, they should be locked based on the suggested versions from terraform init.
  version = "~> 3.15.0"
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_canonical_user_id" "current" {}

locals {
  common_tags = {
    environment  = var.environment
    resourcetier = var.resourcetier
    conflictkey  = "${var.resourcetier}${var.pipelineid}" # The conflict key defines a name space where duplicate resources in different deployments sharing this name can be uniquely recognised
    pipelineid   = var.pipelineid
    owner        = data.aws_canonical_user_id.current.display_name
    accountid    = data.aws_caller_identity.current.account_id
    terraform    = "true"
  }
}

resource "aws_ssm_parameter" "firehawk_onsite_public_ip" {
  name  = "/firehawk/conflictkey/${lookup(var.common_tags, "conflictkey", "0")}/onsite_public_ip"
  value = var.onsite_public_ip
  tags  = merge(map("Name", "firehawk_onsite_public_ip"), var.common_tags)
}

resource "aws_ssm_parameter" "firehawk_onsite_private_subnet_cidr" {
  name  = "/firehawk/conflictkey/${lookup(var.common_tags, "conflictkey", "0")}/onsite_private_subnet_cidr"
  value = var.onsite_private_subnet_cidr
  tags  = merge(map("Name", "firehawk_onsite_private_subnet_cidr"), var.common_tags)
}

resource "aws_ssm_parameter" "firehawk_bucket_extension" {
  name  = "/firehawk/conflictkey/${lookup(var.common_tags, "conflictkey", "0")}/bucket_extension"
  value = var.bucket_extension
  tags  = merge(map("Name", "firehawk_bucket_extension"), var.common_tags)
}

output "Instructions" {
  value = "Provided you have a static IP, The parameters you have just initialised will only need to be done once.  If your IP changes you may need to update the parameter and subsequent terraform runs frequently."
}