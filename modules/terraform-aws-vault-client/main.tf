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
    conflictkey  = "${var.resourcetier}${var.pipelineid}"
    # The conflict key defines a name space where duplicate resources in different deployments sharing this name are prevented from occuring.  This is used to prevent a new deployment overwriting and existing resource unless it is destroyed first.
    # examples might be blue, green, dev1, dev2, dev3...dev100.  This allows us to lock deployments on some resources.
    pipelineid = var.pipelineid
    owner      = data.aws_canonical_user_id.current.display_name
    accountid  = data.aws_caller_identity.current.account_id
    region     = data.aws_region.current.name
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

data "vault_generic_secret" "onsite_public_ip" { # The remote onsite IP address
  path = "${local.mount_path}/network/onsite_public_ip"
}

data "vault_generic_secret" "vpn_cidr" { # Get the map of data at the path
  path = "${local.mount_path}/network/vpn_cidr"
}
data "vault_generic_secret" "onsite_private_subnet_cidr" { # Get the map of data at the path
  path = "${local.mount_path}/network/onsite_private_subnet_cidr"
}
data "aws_security_group" "bastion" { # Aquire the security group ID for external bastion hosts, these will require SSH access to this internal host.  Since multiple deployments may exist, the pipelineid allows us to distinguish between unique deployments.
  tags   = map("Name", "bastion_pipeid${lookup(local.common_tags, "pipelineid", "0")}")
  vpc_id = data.aws_vpc.primary.id
}

locals {
  mount_path           = var.resourcetier
  vpc_id               = data.aws_vpc.primary.id
  vpc_cidr             = data.aws_vpc.primary.cidr_block
  aws_internet_gateway = data.aws_internet_gateway.gw.id

  vpn_cidr                   = lookup(data.vault_generic_secret.vpn_cidr.data, "value")
  onsite_private_subnet_cidr         = lookup(data.vault_generic_secret.onsite_private_subnet_cidr.data, "value")

  private_subnet_ids         = tolist(data.aws_subnet_ids.private.ids)
  private_subnet_cidr_blocks = [for s in data.aws_subnet.private : s.cidr_block]
  private_domain             = lookup(data.vault_generic_secret.private_domain.data, "value")
  onsite_public_ip           = lookup(data.vault_generic_secret.onsite_public_ip.data, "value")
  private_route_table_ids    = data.aws_route_tables.private.ids
  # public_route_table_ids     = data.aws_route_tables.public.ids
  # public_domain_name         = "none"
}
module "vault_client" {
  source              = "./modules/vault-client"
  name                = "vaultclient_pipeid${lookup(local.common_tags, "pipelineid", "0")}"
  vault_client_ami_id = var.vault_client_ami_id
  aws_internal_domain = var.aws_internal_domain
  vpc_id              = local.vpc_id
  vpc_cidr            = local.vpc_cidr

  private_subnet_ids  = local.private_subnet_ids
  permitted_cidr_list = ["${local.onsite_public_ip}/32", var.remote_cloud_public_ip_cidr, var.remote_cloud_private_ip_cidr, local.onsite_private_subnet_cidr, local.vpn_cidr]
  security_group_ids  = [data.aws_security_group.bastion.id]

  # aws_key_name = var.aws_key_name
  common_tags = local.common_tags
}
