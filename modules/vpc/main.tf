provider "null" {
  version = "~> 3.0"
}

provider "aws" {
  # in a dev environment these version locks below can be disabled.  in production, they should be locked based on the suggested versions from terraform init.
  version = "~> 3.15.0"
}
locals {
  common_tags = var.common_tags
}
module "vpc" {
  source                       = "./modules/terraform-aws-vpc"
  vpc_name                     = local.common_tags["vpcname"]
  enable_nat_gateway           = var.enable_nat_gateway
  vpc_cidr                     = var.vpc_cidr
  public_subnets               = var.public_subnets
  private_subnets              = var.private_subnets
  sleep                        = var.sleep
  common_tags                  = local.common_tags
}

module "consul_client_security_group" {
  source              = "./modules/consul-client-security-group"
  common_tags         = local.common_tags
  create_vpc          = true
  vpc_id              = module.vpc.vpc_id
}
