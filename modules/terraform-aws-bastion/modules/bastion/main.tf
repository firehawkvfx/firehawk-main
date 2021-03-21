data "aws_region" "current" {}

data "terraform_remote_state" "bastion_security_group" { # read the arn with data.terraform_remote_state.packer_profile.outputs.instance_role_arn, or read the profile name with data.terraform_remote_state.packer_profile.outputs.instance_profile_name
  backend = "s3"
  config = {
    bucket = "state.terraform.${var.bucket_extension_vault}"
    key    = "firehawk-main/modules/terraform-aws-sg-bastion/terraform.tfstate"
    region = data.aws_region.current.name
  }
}
data "terraform_remote_state" "bastion_profile" { # read the arn with data.terraform_remote_state.packer_profile.outputs.instance_role_arn, or read the profile name with data.terraform_remote_state.packer_profile.outputs.instance_profile_name
  backend = "s3"
  config = {
    bucket = "state.terraform.${var.bucket_extension_vault}"
    key    = "firehawk-main/modules/terraform-aws-iam-profile-bastion/terraform.tfstate"
    region = data.aws_region.current.name
  }
}
locals {
  bastion_tags = merge(var.common_tags, {
    name  = var.name
    role  = "bastion"
    route = "public"
  })
  public_ip       = element(concat(aws_instance.bastion.*.public_ip, list("")), 0)
  private_ip      = element(concat(aws_instance.bastion.*.private_ip, list("")), 0)
  public_dns      = element(concat(aws_instance.bastion.*.public_dns, list("")), 0)
  id              = element(concat(aws_instance.bastion.*.id, list("")), 0)
  bastion_address = var.route_public_domain_name ? "bastion.${var.public_domain_name}" : local.public_ip
}
resource "aws_instance" "bastion" {
  count                  = var.create_vpc ? 1 : 0
  ami                    = var.bastion_ami_id
  instance_type          = var.instance_type
  key_name               = var.aws_key_name # The PEM key is disabled for use in production, can be used for debugging.  Instead, signed SSH certificates should be used to access the host.
  subnet_id              = tolist(var.public_subnet_ids)[0]
  tags                   = local.bastion_tags
  user_data              = data.template_file.user_data_auth_client.rendered
  iam_instance_profile   = data.terraform_remote_state.bastion_profile.outputs.instance_profile_name
  vpc_security_group_ids = [ data.terraform_remote_state.bastion_security_group.outputs.security_group_id ]
  root_block_device {
    delete_on_termination = true
  }
}

resource "vault_token" "ssh_host" { # dynamically generate a token with constrained permisions for the host role.
  role_name        = "host-vault-token-creds-role"
  policies         = ["ssh_host"]
  renewable        = false
  explicit_max_ttl = "120s"
}
data "template_file" "user_data_auth_client" {
  template = file("${path.module}/user-data-auth-ssh-host-vault-token.sh")
  vars = {
    consul_cluster_tag_key   = var.consul_cluster_tag_key
    consul_cluster_tag_value = var.consul_cluster_name
    vault_token              = vault_token.ssh_host.client_token
    aws_internal_domain      = var.aws_internal_domain
    aws_external_domain      = var.aws_external_domain
  }
}
resource "aws_route53_record" "bastion_record" {
  count   = var.route_public_domain_name && var.create_vpc ? 1 : 0
  zone_id = element(concat(list(var.route_zone_id), list("")), 0)
  name    = element(concat(list("bastion.${var.public_domain_name}"), list("")), 0)
  type    = "A"
  ttl     = 300
  records = [local.public_ip]
}
