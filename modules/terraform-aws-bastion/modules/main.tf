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
    environment  = "prod"
    resourcetier = "main"
    conflictkey  = "main1"
    # The conflict key defines a name space where duplicate resources in different deployments sharing this name are prevented from occuring.  This is used to prevent a new deployment overwriting and existing resource unless it is destroyed first.
    # examples might be blue, green, dev1, dev2, dev3...dev100.  This allows us to lock deployments on some resources.
    pipelineid = "0"
    owner      = data.aws_canonical_user_id.current.display_name
    accountid  = data.aws_caller_identity.current.account_id
    terraform  = "true"
  }
}

data "aws_vpc" "primary" {
  default = false
  tags    = local.common_tags
}
data "aws_internet_gateway" "gw" {
  # default = false
  tags = local.common_tags
}

data "aws_subnet_ids" "public" {
  vpc_id = data.aws_vpc.primary.id
  tags   = map("area", "public")
}

data "aws_subnet" "public" {
  for_each = data.aws_subnet_ids.public.ids
  id       = each.value
}

data "aws_subnet_ids" "private" {
  vpc_id = data.aws_vpc.primary.id
  tags   = map("area", "private")
}

data "aws_subnet" "private" {
  for_each = data.aws_subnet_ids.private.ids
  id       = each.value
}

data "aws_route_tables" "public" {
  vpc_id = data.aws_vpc.primary.id
  tags   = map("area", "public")
}

data "aws_route_tables" "private" {
  vpc_id = data.aws_vpc.primary.id
  tags   = map("area", "private")
}

data "vault_generic_secret" "private_domain" { # Get the map of data at the path
  path = "${local.mount_path}/network/private_domain"
}

data "vault_generic_secret" "vpn_cidr" { # Get the map of data at the path
  path = "${local.mount_path}/network/vpn_cidr"
}

data "vault_generic_secret" "remote_public_ip" { # Get the map of data at the path
  path = "${local.mount_path}/network/remote_public_ip"
}

data "vault_generic_secret" "remote_subnet_cidr" { # Get the map of data at the path
  path = "${local.mount_path}/network/remote_subnet_cidr"
}

data "vault_generic_secret" "openvpn_user_pw" { # Get the map of data at the path
  path = "${local.mount_path}/network/openvpn_user_pw"
}

data "vault_generic_secret" "openvpn_admin_pw" { # Get the map of data at the path
  path = "${local.mount_path}/network/openvpn_admin_pw"
}

locals {
  private_key                = fileexists(var.aws_private_key_path) ? file(var.aws_private_key_path) : ""
  mount_path                 = var.resourcetier
  vpc_id                     = data.aws_vpc.primary.id
  vpc_cidr                   = data.aws_vpc.primary.cidr_block
  aws_internet_gateway       = data.aws_internet_gateway.gw.id
  public_subnets             = data.aws_subnet_ids.public.ids
  public_subnet_cidr_blocks  = [for s in data.aws_subnet.public : s.cidr_block]
  private_subnets            = data.aws_subnet_ids.private.ids
  private_subnet_cidr_blocks = [for s in data.aws_subnet.private : s.cidr_block]
  private_domain             = lookup(data.vault_generic_secret.private_domain.data, "value")
  #   vpn_cidr                   = lookup(data.vault_generic_secret.vpn_cidr.data, "value")
  remote_public_ip        = lookup(data.vault_generic_secret.remote_public_ip.data, "value")
  remote_subnet_cidr      = lookup(data.vault_generic_secret.remote_subnet_cidr.data, "value")
  private_route_table_ids = data.aws_route_tables.private.ids
  public_route_table_ids  = data.aws_route_tables.public.ids
  public_domain_name      = "none"
  route_zone_id           = "none"
}


module "bastion" {
  source = "./modules/bastion"

  name           = "bastion_pipeid${lookup(local.common_tags, "pipelineid", "0")}"
  bastion_ami_id = var.bastion_ami_id

  route_public_domain_name = var.route_public_domain_name

  #options for gateway type are centos7 and pcoip
  vpc_id   = local.vpc_id
  vpc_cidr = local.vpc_cidr
  #   vpn_cidr                    = local.vpn_cidr
  remote_ip_cidr             = "${local.remote_public_ip}/32"
  public_subnet_ids          = local.public_subnets
  public_subnets_cidr_blocks = local.public_subnet_cidr_blocks
  # private_subnets_cidr_blocks = local.private_subnets_cidr_blocks
  remote_subnet_cidr = local.remote_subnet_cidr

  aws_key_name         = var.aws_key_name
  aws_private_key_path = var.aws_private_key_path
  private_key          = local.private_key

  route_zone_id      = local.route_zone_id
  public_domain_name = local.public_domain_name

  #skipping os updates will allow faster rollout for testing.
  # skip_update = var.node_skip_update

  #sleep will stop instances to save cost during idle time.
  sleep = var.sleep

  common_tags = local.common_tags
}
