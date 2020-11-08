provider "null" {
  version = "~> 3.0"
}

provider "aws" {
  #  if you haven't installed and configured the aws cli, you will need to provide your aws access key and secret key.
  # in a dev environment these version locks below can be disabled.  in production, they should be locked based on the suggested versions from terraform init.
  version = "~> 3.3.0"
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

# resource "tls_private_key" "main" {
#   algorithm = "RSA"
# }

module "key_pair" {
  source = "terraform-aws-modules/key-pair/aws"

  key_name   = "main-deployment"
  # public_key = tls_private_key.main.public_key_openssh
  public_key = var.vault_public_key
  tags = local.common_tags
}

module "vpc" {
  source = "./modules/terraform-aws-vpc-vpn"
  # region = data.aws_region.current.name

#   firehawk_init_dependency = module.firehawk_init.init_awscli_complete
#   create_vpc = var.enable_vpc
#   route_public_domain_name = var.route_public_domain_name
#   private_domain = var.private_domain
  sleep              = var.sleep
  create_bastion = true
  bastion_ami_id = var.bastion_ami_id
#   enable_nat_gateway = var.enable_nat_gateway
#   azs = var.azs

#   private_subnets = [var.private_subnet1, var.private_subnet2]
#   public_subnets  = [var.public_subnet1, var.public_subnet2]

#   vpc_cidr = var.vpc_cidr

#   #vpn variables
#   vpn_cidr = var.vpn_cidr
  remote_ip_cidr = var.remote_ip_cidr
  remote_subnet_cidr = var.remote_ip_cidr # this is a dummy address. normally for the vpn to function this should be the cidr range of your private subnet

#   #a provided route 53 zone id will be modified to have a subdomain to access vpn.  you will need to manually setup a route 53 zone for a domain with an ssl certificate.

  aws_key_name           = module.key_pair.this_key_pair_key_name
  aws_private_key_path     = var.aws_private_key_path
#   route_zone_id      = var.route_zone_id
#   public_domain_name = var.public_domain
#   cert_arn           = var.cert_arn
#   openvpn_user       = var.openvpn_user
#   openvpn_user_pw    = var.openvpn_user_pw
#   openvpn_admin_user = var.openvpn_admin_user
#   openvpn_admin_pw   = var.openvpn_admin_pw

#   vpc_name = local.name
  common_tags = local.common_tags
}

module "vault" {
  source = "./modules/terraform-aws-vault"
  
  count = var.enable_vault ? 1 : 0
  depends_on = [module.vpc]
  
  use_default_vpc = false
  vpc_tags = local.common_tags #tags used to find the vpc to deploy into.
  subnet_tags =  map("area", "private")

  enable_auto_unseal = true
  
  ssh_key_name = module.key_pair.this_key_pair_key_name

  # Persist vault data in an S3 bucket when all nodes are shut down.
  enable_s3_backend = true
  s3_bucket_name = "vault.${var.bucket_extension}"

  ami_id = var.vault_consul_ami_id
}