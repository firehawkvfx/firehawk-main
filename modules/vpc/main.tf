provider "null" {
  version = "~> 3.0"
}

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
    # The conflict key defines a name space where duplicate resources in different deployments sharing this name are prevented from occuring.  This is used to prevent a new deployment overwriting and existing resource unless it is destroyed first.
    # examples might be blue, green, dev1, dev2, dev3...dev100.  This allows us to lock deployments on some resources.
    pipelineid   = "0"
    owner        = data.aws_canonical_user_id.current.display_name
    accountid    = data.aws_caller_identity.current.account_id
    terraform    = "true"
  }
}

module "key_pair" {
  source = "terraform-aws-modules/key-pair/aws"

  key_name   = "main-deployment" 
  public_key = var.vault_public_key
  tags = local.common_tags
}

module "vpc" {
  source = "../terraform-aws-vpc-vpn"

  sleep          = var.sleep
  create_bastion = true
  create_bastion_graphical = var.create_bastion_graphical
  bastion_ami_id = var.bastion_ami_id
  bastion_graphical_ami_id = var.bastion_graphical_ami_id

  remote_ip_cidr = var.remote_ip_cidr
  remote_ip_graphical_cidr = var.remote_ip_graphical_cidr
  remote_subnet_cidr = var.remote_ip_cidr # this is a dummy address. normally for the vpn to function this should be the cidr range of your private subnet

  aws_key_name           = module.key_pair.this_key_pair_key_name
  aws_private_key_path     = var.aws_private_key_path

  common_tags = local.common_tags
}