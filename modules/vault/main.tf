provider "null" {
  version = "~> 3.0"
}
provider "aws" {
  #  if you haven't installed and configured the aws cli, you will need to provide your aws access key and secret key.
  # in a dev environment these version locks below can be disabled.  in production, they should be locked based on the suggested versions from terraform init.
  version = "~> 3.15.0"
}
locals {
  common_tags = var.common_tags
}
module "vault" {
  # source             = "../../modules/terraform-aws-vault"
  # source = "github.com/firehawkvfx/firehawk-main.git//modules/terraform-aws-vault?ref=v0.0.7"
  source = "github.com/firehawkvfx/firehawk-main.git//modules/terraform-aws-vault?ref=restore-missing-iam"
  # source             = "github.com/queglay/terraform-aws-vault.git//?ref=dev"

  use_default_vpc    = false
  vpc_tags           = local.common_tags #tags used to find the vpc to deploy into.
  subnet_tags        = map("area", "private")
  enable_auto_unseal = true
  ssh_key_name       = var.aws_key_name
  # Persist vault data in an S3 bucket when all nodes are shut down.
  enable_s3_backend      = true
  use_existing_s3_bucket = true
  s3_bucket_name         = "vault.${var.bucket_extension}"
  ami_id                 = var.vault_consul_ami_id
  consul_cluster_name    = var.consul_cluster_name
  consul_cluster_tag_key = var.consul_cluster_tag_key
  resourcetier           = var.resourcetier
  common_tags            = var.common_tags
}

### Configure the current cloud9 instance to connect to vault ###
data "aws_vpc" "primary" { # The primary is the Main VPC containing vault
  default = false
  tags    = local.common_tags
}
data "aws_vpc" "secondary" { # The secondary is the VPC containing the cloud 9 instance. 
  id = var.vpc_id_main_cloud9
}
# security_group_id_consul_cluster
data "aws_instance" "main_cloud9" {
  instance_id = var.instance_id_main_cloud9
}
resource "aws_security_group" "cloud9_to_vault" {
  name        = "cloud9_to_vault_${var.resourcetier}${var.pipelineid}"
  description = "Security group for Cloud 9 access to Consul and Vault"
  vpc_id      = data.aws_vpc.secondary.id
}
module "security_group_rules" {
  source                               = "github.com/hashicorp/terraform-aws-consul.git//modules/consul-client-security-group-rules?ref=v0.8.0"
  security_group_id                    = aws_security_group.cloud9_to_vault.id
  allowed_inbound_security_group_ids   = [module.vault.security_group_id_consul_cluster]
  allowed_inbound_security_group_count = 1
  allowed_inbound_cidr_blocks          = [data.aws_vpc.primary.cidr_block] # TODO test if its possible only inbound sg or cidr block is required.
  # TODO define var.allowed_inbound_security_group_ids, allowed_inbound_security_group_count and var.allowed_inbound_cidr_blocks
}
resource "aws_network_interface_sg_attachment" "sg_attachment_consul_cluster" {
  security_group_id    = aws_security_group.cloud9_to_vault.id
  network_interface_id = data.aws_instance.main_cloud9.network_interface_id
}

# need to compare this sg group with DCV instance.
# 
