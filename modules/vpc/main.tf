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

module "vpc" {
  source                       = "../terraform-aws-vpc"
  vpc_name                     = "${var.resourcetier}_vpc"
  vpc_cidr                     = module.vaultvpc_all_subnet_cidrs.base_cidr_block
  public_subnets               = [module.vaultvpc_all_public_subnet_cidrs.network_cidr_blocks["publicsubnet1"]]
  private_subnets              = [module.vaultvpc_all_private_subnet_cidrs.network_cidr_blocks["privatesubnet1"]]
  sleep                        = var.sleep
  deployer_ip_cidr             = var.deployer_ip_cidr
  remote_cloud_public_ip_cidr  = var.remote_cloud_public_ip_cidr
  remote_cloud_private_ip_cidr = var.remote_cloud_private_ip_cidr
  common_tags                  = local.common_tags
}

module "resourcetier_all_vpc_cidrs" { # all vpcs contained in the resource tier dev / green / blue / main
  source = "hashicorp/subnets/cidr"

  base_cidr_block = "10.1.0.0/16"
  networks = [
    {
      name     = "vaultvpc"
      new_bits = 8
    },
    {
      name     = "rendervpc"
      new_bits = 1
    }
  ]
}

module "vaultvpc_all_subnet_cidrs" { # all private/public subnet ranges 
  source = "hashicorp/subnets/cidr"

  base_cidr_block = module.resourcetier_all_vpc_cidrs.network_cidr_blocks["vaultvpc"]
  networks = [
    {
      name     = "privatesubnets"
      new_bits = 1
    },
    {
      name     = "publicsubnets"
      new_bits = 1
    }
  ]
}

module "vaultvpc_all_private_subnet_cidrs" {
  source = "hashicorp/subnets/cidr"

  base_cidr_block = module.vaultvpc_all_subnet_cidrs.network_cidr_blocks["privatesubnets"]
  networks = [
    {
      name     = "privatesubnet1"
      new_bits = 2
    },
    {
      name     = "privatesubnet2"
      new_bits = 2
    }
  ]
}

module "vaultvpc_all_public_subnet_cidrs" {
  source = "hashicorp/subnets/cidr"

  base_cidr_block = module.vaultvpc_all_subnet_cidrs.network_cidr_blocks["publicsubnets"]
  networks = [
    {
      name     = "publicsubnet1"
      new_bits = 2
    },
    {
      name     = "publicsubnet2"
      new_bits = 2
    }
  ]
}

output "resourcetier_all_vpc_cidrs" {
  value = module.resourcetier_all_vpc_cidrs.network_cidr_blocks
}

output "vaultvpc_all_subnet_cidrs" {
  value = module.vaultvpc_all_subnet_cidrs.network_cidr_blocks
}

output "vaultvpc_all_private_subnet_cidrs" {
  value = module.vaultvpc_all_private_subnet_cidrs.network_cidr_blocks
}

output "vaultvpc_all_public_subnet_cidrs" {
  value = module.vaultvpc_all_public_subnet_cidrs.network_cidr_blocks
}