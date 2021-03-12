provider "aws" {
  #  if you haven't installed and configured the aws cli, you will need to provide your aws access key and secret key.
  # in a dev environment these version locks below can be disabled.  in production, they should be locked based on the suggested versions from terraform init.
  version = "~> 3.15.0"
}
module "key_pair" {
  source = "terraform-aws-modules/key-pair/aws"

  key_name   = "deployuser-${var.resourcetier}"
  public_key = var.vault_public_key
  tags = var.common_tags
}