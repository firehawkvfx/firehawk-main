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

module "vault" {
  source = "../../modules/terraform-aws-vault"
  
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

### Configure peering between the cloud 9 instance and the main vpc for vault to be configured by terraform. ###

data "aws_vpc" "primary" { # The primary is the Main VPC containing vault
  default = false
  tags    = local.common_tags
}

data "aws_vpc" "secondary" { # The secondary is the VPC containing the cloud 9 instance. 
  id = var.vpc_id_main_cloud9
}

resource "aws_vpc_peering_connection" "primary2secondary" {
  vpc_id = data.aws_vpc.primary.id # Main VPC ID.
  peer_vpc_id = data.aws_vpc.secondary.id # Secondary VPC ID.
  auto_accept = true # Flags that the peering connection should be automatically confirmed. This only works if both VPCs are owned by the same account.

  # # AWS Account ID. This can be dynamically queried using the
  # # aws_caller_identity data resource.
  # # https://www.terraform.io/docs/providers/aws/d/caller_identity.html
  # peer_owner_id = "${data.aws_caller_identity.current.account_id}"
}

data "aws_route_table" "main_private" {
  tags = {
    "conflictkey": local.common_tags["conflictkey"],
    "pipelineid": local.common_tags["pipelineid"],
    "area": "private",
  }
}

data "aws_route_table" "main_public" {
  tags = {
    "conflictkey": local.common_tags["conflictkey"],
    "pipelineid": local.common_tags["pipelineid"],
    "area": "public",
  }
}

resource "aws_route" "primaryprivate2secondary" {
  route_table_id = data.aws_route_table.main_private.id
  destination_cidr_block = data.aws_vpc.secondary.cidr_block # CIDR block / IP range for VPC 2.
  vpc_peering_connection_id = aws_vpc_peering_connection.primary2secondary.id # ID of VPC peering connection.
}

resource "aws_route" "primarypublic2secondary" {
  route_table_id = data.aws_route_table.main_public.id
  destination_cidr_block = data.aws_vpc.secondary.cidr_block # CIDR block / IP range for VPC 2.
  vpc_peering_connection_id = aws_vpc_peering_connection.primary2secondary.id # ID of VPC peering connection.
}

resource "aws_route" "secondary2primary" {
  route_table_id = data.aws_vpc.secondary.main_route_table_id # ID of VPC 2 main route table.
  destination_cidr_block = data.aws_vpc.primary.cidr_block # CIDR block / IP range for VPC 2.
  vpc_peering_connection_id = aws_vpc_peering_connection.primary2secondary.id # ID of VPC peering connection.
}

### Configure the current cloud9 instance to connect to vault ###

# security_group_id_consul_cluster

data "aws_instance" "main_cloud9" {
  instance_id = var.instance_id_main_cloud9
}

resource "aws_security_group" "cloud9_to_vault" {
  name        = "cloud9_to_vault"
  description = "Security group for Cloud 9 access to Consul and Vault"
  vpc_id      = data.aws_vpc.secondary.id
}

module "security_group_rules" {
  source = "github.com/hashicorp/terraform-aws-consul.git//modules/consul-client-security-group-rules?ref=v0.8.0"
  security_group_id = aws_security_group.cloud9_to_vault.id
  allowed_inbound_security_group_ids = [module.vault.security_group_id_consul_cluster]
  allowed_inbound_security_group_count = 1
  allowed_inbound_cidr_blocks = [ data.aws_vpc.primary.cidr_block ] # TODO test if its possible only inbound sg or cidr block is required.
  # TODO define var.allowed_inbound_security_group_ids, allowed_inbound_security_group_count and var.allowed_inbound_cidr_blocks
}

resource "aws_network_interface_sg_attachment" "sg_attachment_consul_cluster" {
  security_group_id    = aws_security_group.cloud9_to_vault.id
  network_interface_id = data.aws_instance.main_cloud9.network_interface_id
}

# need to compare this sg group with DCV instance.
# 