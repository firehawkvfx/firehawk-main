provider "null" {
  version = "~> 3.0"
}

provider "aws" {
  #  if you haven't installed and configured the aws cli, you will need to provide your aws access key and secret key.
  # in a dev environment these version locks below can be disabled.  in production, they should be locked based on the suggested versions from terraform init.
  version = "~> 3.15.0"
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

locals {
  common_tags                = var.common_tags
  mount_path                 = var.resourcetier
  vpc_id                     = data.aws_vpc.primary.id
  vpc_cidr                   = data.aws_vpc.primary.cidr_block
  aws_internet_gateway       = data.aws_internet_gateway.gw.id
  public_subnets             = tolist(data.aws_subnet_ids.public.ids)
  public_subnet_cidr_blocks  = [for s in data.aws_subnet.public : s.cidr_block]
  private_subnets            = tolist(data.aws_subnet_ids.private.ids)
  private_subnet_cidr_blocks = [for s in data.aws_subnet.private : s.cidr_block]
  onsite_public_ip           = var.onsite_public_ip
  private_route_table_ids    = data.aws_route_tables.private.ids
  public_route_table_ids     = data.aws_route_tables.public.ids
  public_domain_name         = "none"
  route_zone_id              = "none"
  instance_name              = "${lookup(local.common_tags, "vpcname", "default")}_bastion_pipeid${lookup(local.common_tags, "pipelineid", "0")}"
}
module "bastion" {
  source = "./modules/bastion"
  # name                   = "bastion_pipeid${lookup(local.common_tags, "pipelineid", "0")}"
  name                   = local.instance_name
  bastion_ami_id         = var.bastion_ami_id
  consul_cluster_tag_key = var.consul_cluster_tag_key
  consul_cluster_name    = var.consul_cluster_name
  aws_key_name           = var.aws_key_name # The aws pem key name can optionally be enabled for debugging, but generally SSH certificates should be used instead.
  aws_internal_domain    = var.aws_internal_domain
  aws_external_domain    = var.aws_external_domain
  vpc_id                 = local.vpc_id
  vpc_cidr               = local.vpc_cidr
  # permitted_cidr_list      = ["${local.onsite_public_ip}/32", var.remote_cloud_public_ip_cidr, var.remote_cloud_private_ip_cidr]
  public_subnet_ids        = local.public_subnets
  route_public_domain_name = var.route_public_domain_name
  route_zone_id            = local.route_zone_id
  public_domain_name       = local.public_domain_name
  common_tags              = local.common_tags
  bucket_extension_vault   = var.bucket_extension_vault
  resourcetier_vault       = var.resourcetier_vault
  vpcname_vaultvpc            = var.vpcname_vaultvpc
}
