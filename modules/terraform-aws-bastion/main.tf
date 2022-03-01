provider "null" {
  version = "~> 3.0"
}
provider "aws" {
  #  if you haven't installed and configured the aws cli, you will need to provide your aws access key and secret key.
  # in a dev environment these version locks below can be disabled.  in production, they should be locked based on the suggested versions from terraform init.
  version = "~> 3.15.0"
}
data "terraform_remote_state" "vaultvpc" {
  backend = "s3"
  config = {
    bucket = "state.terraform.${var.bucket_extension_vault}"
    key    = "firehawk-main/modules/vpc/terraform.tfstate"
    region = data.aws_region.current.name
  }
}
locals {
  vpc_id = length(data.terraform_remote_state.vaultvpc.outputs.vpc_id) > 0 ? data.terraform_remote_state.vaultvpc.outputs.vpc_id : ""
}
data "aws_vpc" "primary" {
  count   = length(local.vpc_id) > 0 ? 1 : 0
  default = false
  id      = local.vpc_id
}

data "aws_subnets" "public" {
  count  = length(local.vpc_id) > 0 ? 1 : 0
  vpc_id = local.vpc_id
  tags   = map("area", "public")
}

data "aws_subnet" "public" {
  count    = length(data.aws_subnets.public) > 0 ? 1 : 0
  for_each = length(data.aws_subnets.public) > 0 ? data.aws_subnets.public[0].ids : []
  id       = each.value
}

locals {
  common_tags      = var.common_tags
  vpc_cidr         = length(data.aws_vpc.primary) > 0 ? data.aws_vpc.primary[0].cidr_block : ""
  public_subnets   = length(data.aws_subnets.public) > 0 ? tolist(data.aws_subnets.public[0].ids) : []
  onsite_public_ip = var.onsite_public_ip
}
module "bastion" {
  source                 = "./modules/bastion"
  name                   = "${lookup(local.common_tags, "vpcname", "default")}_bastion_pipeid${lookup(local.common_tags, "pipelineid", "0")}"
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
  route_zone_id            = "none"
  public_domain_name       = local.public_domain_name
  common_tags              = local.common_tags
  bucket_extension_vault   = var.bucket_extension_vault
  resourcetier_vault       = var.resourcetier_vault
  vpcname_vaultvpc         = var.vpcname_vaultvpc
}
