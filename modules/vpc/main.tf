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
  vpc_cidr                     = module.vaultvpc_all_subnet_cidrs.base_cidr_block
  public_subnets               = module.vaultvpc_all_public_subnet_cidrs.networks[*].cidr_block
  private_subnets              = module.vaultvpc_all_private_subnet_cidrs.networks[*].cidr_block
  sleep                        = var.sleep
  deployer_ip_cidr             = var.deployer_ip_cidr
  remote_cloud_public_ip_cidr  = var.remote_cloud_public_ip_cidr
  remote_cloud_private_ip_cidr = var.remote_cloud_private_ip_cidr
  common_tags                  = local.common_tags
}

module "consul_client_security_group" {
  source              = "./modules/consul-client-security-group"
  common_tags         = local.common_tags
  create_vpc          = true
  vpc_id              = module.vpc.vpc_id
}

module "resourcetier_all_vpc_cidrs" { # all vpcs contained in the combined_vpcs_cidr (current resource tier dev or green or blue or main)
  source = "hashicorp/subnets/cidr"

  base_cidr_block = var.combined_vpcs_cidr
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
    for i in range(var.vault_vpc_subnet_count) : { name = format("privatesubnet%s", i), new_bits = 2 }
  ]
}

module "vaultvpc_all_public_subnet_cidrs" {
  source = "hashicorp/subnets/cidr"

  base_cidr_block = module.vaultvpc_all_subnet_cidrs.network_cidr_blocks["publicsubnets"]
  networks = [
    for i in range(var.vault_vpc_subnet_count) : { name = format("publicsubnet%s", i), new_bits = 2 }
  ]
}
