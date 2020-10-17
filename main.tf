provider "aws" {
  #  if you haven't installed and configured the aws cli, you will need to provide your aws access key and secret key.
  region = var.aws_region
  # in a dev environment these version locks below can be disabled.  in production, they should be locked based on the suggested versions from terraform init.
  version = "~> 3.3.0"
}

provider "null" {
  version = "~> 3.0"
}

module "vpc" {
  source = "./modules/terraform-aws-vpc-vpn"

#   firehawk_init_dependency = module.firehawk_init.init_awscli_complete
#   create_vpc = var.enable_vpc
#   route_public_domain_name = var.route_public_domain_name
#   private_domain = var.private_domain
#   sleep              = var.sleep
#   enable_nat_gateway = var.enable_nat_gateway
#   azs = var.azs

#   private_subnets = [var.private_subnet1, var.private_subnet2]
#   public_subnets  = [var.public_subnet1, var.public_subnet2]

#   vpc_cidr = var.vpc_cidr

#   #vpn variables
#   vpn_cidr = var.vpn_cidr
#   remote_ip_cidr = var.remote_ip_cidr
#   remote_subnet_cidr = var.remote_subnet_cidr

#   #a provided route 53 zone id will be modified to have a subdomain to access vpn.  you will need to manually setup a route 53 zone for a domain with an ssl certificate.

#   aws_key_name           = var.aws_key_name
#   aws_private_key_path     = var.aws_private_key_path
#   route_zone_id      = var.route_zone_id
#   public_domain_name = var.public_domain
#   cert_arn           = var.cert_arn
#   openvpn_user       = var.openvpn_user
#   openvpn_user_pw    = var.openvpn_user_pw
#   openvpn_admin_user = var.openvpn_admin_user
#   openvpn_admin_pw   = var.openvpn_admin_pw

#   vpc_name = local.name
#   common_tags = local.common_tags
}
