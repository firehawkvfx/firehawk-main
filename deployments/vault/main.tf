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

# resource "tls_private_key" "main" {
#   algorithm = "RSA"
# }

# module "key_pair" {
#   source = "terraform-aws-modules/key-pair/aws"

#   key_name   = "main-deployment" 
#   public_key = var.vault_public_key
#   tags = local.common_tags
# }

# module "vpc" {
#   source = "./modules/terraform-aws-vpc-vpn"
#   # region = data.aws_region.current.name

# #   firehawk_init_dependency = module.firehawk_init.init_awscli_complete
# #   create_vpc = var.enable_vpc
# #   route_public_domain_name = var.route_public_domain_name
# #   private_domain = var.private_domain
#   sleep          = var.sleep
#   create_bastion = true
#   create_bastion_graphical = var.create_bastion_graphical
#   bastion_ami_id = var.bastion_ami_id
#   bastion_graphical_ami_id = var.bastion_graphical_ami_id
# #   enable_nat_gateway = var.enable_nat_gateway
# #   azs = var.azs

# #   private_subnets = [var.private_subnet1, var.private_subnet2]
# #   public_subnets  = [var.public_subnet1, var.public_subnet2]

# #   vpc_cidr = var.vpc_cidr

# #   #vpn variables
# #   vpn_cidr = var.vpn_cidr
#   remote_ip_cidr = var.remote_ip_cidr
#   remote_ip_graphical_cidr = var.remote_ip_graphical_cidr
#   remote_subnet_cidr = var.remote_ip_cidr # this is a dummy address. normally for the vpn to function this should be the cidr range of your private subnet

# #   #a provided route 53 zone id will be modified to have a subdomain to access vpn.  you will need to manually setup a route 53 zone for a domain with an ssl certificate.

#   aws_key_name           = module.key_pair.this_key_pair_key_name
#   aws_private_key_path     = var.aws_private_key_path
# #   route_zone_id      = var.route_zone_id
# #   public_domain_name = var.public_domain
# #   cert_arn           = var.cert_arn
# #   openvpn_user       = var.openvpn_user
# #   openvpn_user_pw    = var.openvpn_user_pw
# #   openvpn_admin_user = var.openvpn_admin_user
# #   openvpn_admin_pw   = var.openvpn_admin_pw

# #   vpc_name = local.name
#   common_tags = local.common_tags
# }

module "vault" {
  source = "../../modules/terraform-aws-vault"
  
  count = var.enable_vault ? 1 : 0
  # depends_on = [module.vpc]
  
  use_default_vpc = false
  vpc_tags = local.common_tags #tags used to find the vpc to deploy into.
  subnet_tags =  map("area", "private")

  enable_auto_unseal = true
  
  ssh_key_name = "main-deployment"

  # Persist vault data in an S3 bucket when all nodes are shut down.
  enable_s3_backend = true
  s3_bucket_name = "vault.${var.bucket_extension}"

  ami_id = var.vault_consul_ami_id
}

# Configure peering between the cloud 9 instance and the main vpc for vault to be configured by terraform.

# output "vpc_id" {
#   value = module.vault.vpc_id
# }

data "aws_vpc" "primary" {
  default = false
  tags    = local.common_tags
}

# data "aws_vpc" "primary" {
#   id = data.aws_vpc.primary.vpc_id
# }

data "aws_vpc" "secondary" {
  id = var.vpc_id_main_cloud9
}

resource "aws_vpc_peering_connection" "primary2secondary" {
  # Main VPC ID.
  vpc_id = data.aws_vpc.primary.id

  # # AWS Account ID. This can be dynamically queried using the
  # # aws_caller_identity data resource.
  # # https://www.terraform.io/docs/providers/aws/d/caller_identity.html
  # peer_owner_id = "${data.aws_caller_identity.current.account_id}"

  # Secondary VPC ID.
  peer_vpc_id = data.aws_vpc.secondary.id

  # Flags that the peering connection should be automatically confirmed. This
  # only works if both VPCs are owned by the same account.
  auto_accept = true
}

resource "aws_route" "primary2secondary" {
  # ID of VPC 1 main route table.
  route_table_id = data.aws_vpc.primary.main_route_table_id

  # CIDR block / IP range for VPC 2.
  destination_cidr_block = data.aws_vpc.secondary.cidr_block

  # ID of VPC peering connection.
  vpc_peering_connection_id = aws_vpc_peering_connection.primary2secondary.id
}

resource "aws_route" "secondary2primary" {
  # ID of VPC 2 main route table.
  route_table_id = data.aws_vpc.secondary.main_route_table_id

  # CIDR block / IP range for VPC 2.
  destination_cidr_block = data.aws_vpc.primary.cidr_block

  # ID of VPC peering connection.
  vpc_peering_connection_id = aws_vpc_peering_connection.primary2secondary.id
}