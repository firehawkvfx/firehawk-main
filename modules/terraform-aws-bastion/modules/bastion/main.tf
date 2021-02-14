#----------------------------------------------------------------
# This module creates all resources necessary for am Ansible Bastion instance in AWS
#----------------------------------------------------------------

variable "common_tags" {}

resource "aws_security_group" "bastion_vpn" {
  count       = var.create_vpc ? 1 : 0
  name        = "bastion_vpn"
  vpc_id      = var.vpc_id
  description = "Bastion Security Group"

  tags = merge(map("Name", format("%s", var.name)), var.common_tags, local.extra_tags)

  # todo need to replace this with correct protocols for pcoip instead of all ports.description
  # ingress {
  #   protocol    = "-1"
  #   from_port   = 0
  #   to_port     = 0
  #   cidr_blocks = [var.vpn_cidr, var.remote_subnet_cidr, "172.27.236.0/24"]
  #   description = "all incoming traffic from remote access ip"
  # }
  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [var.remote_subnet_cidr]
    description = "all incoming traffic from remote access ip"
  }
}

resource "aws_security_group" "bastion" {
  count       = var.create_vpc ? 1 : 0
  name        = var.name
  vpc_id      = var.vpc_id
  description = "Bastion Security Group"

  tags = merge(map("Name", format("%s", var.name)), var.common_tags, local.extra_tags)

  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [var.vpc_cidr]
    description = "all incoming traffic from vpc"
  }

  # For OpenVPN Client Web Server & Admin Web UI

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = var.remote_ip_cidr_list
    description = "ssh"
  }
  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = var.remote_ip_cidr_list
    description = "https"
  }
  ingress {
    protocol    = "udp"
    from_port   = 1194
    to_port     = 1194
    cidr_blocks = var.remote_ip_cidr_list
  }
  ingress {
    protocol    = "icmp"
    from_port   = 8
    to_port     = 0
    cidr_blocks = var.remote_ip_cidr_list
    description = "icmp"
  }
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    description = "all outgoing traffic"
  }
}

locals {
  extra_tags = {
    role  = "bastion"
    route = "public"
  }
}
resource "aws_eip" "bastionip" {
  count    = var.create_vpc ? 1 : 0
  vpc      = true
  instance = aws_instance.bastion[count.index].id
  tags     = merge(map("Name", format("%s", var.name)), var.common_tags, local.extra_tags)
}

resource "aws_instance" "bastion" {
  count         = var.create_vpc ? 1 : 0
  ami           = var.bastion_ami_id
  instance_type = var.instance_type
  key_name      = var.aws_key_name
  subnet_id     = tolist(var.public_subnet_ids)[0]

  vpc_security_group_ids = local.vpc_security_group_ids

  root_block_device {
    delete_on_termination = true
  }
  tags = merge(map("Name", format("%s", var.name)), var.common_tags, local.extra_tags)

  user_data = data.template_file.user_data_auth_client.rendered

  iam_instance_profile = aws_iam_instance_profile.example_instance_profile.name

}

# ---------------------------------------------------------------------------------------------------------------------
# CREATES A ROLE THAT IS ATTACHED TO THE INSTANCE
# The arn of this AWS role is what the Vault server will use create the Vault Role
# so it can validate login requests from resources with this role
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_instance_profile" "example_instance_profile" {
  path = "/"
  role = aws_iam_role.example_instance_role.name
}

resource "aws_iam_role" "example_instance_role" {
  name_prefix        = "${var.name}-role"
  assume_role_policy = data.aws_iam_policy_document.example_instance_role.json
}

data "aws_iam_policy_document" "example_instance_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}
# Adds policies necessary for running consul
module "consul_iam_policies_for_client" {
  source      = "github.com/hashicorp/terraform-aws-consul.git//modules/consul-iam-policies?ref=v0.7.7"
  iam_role_id = aws_iam_role.example_instance_role.id
}

resource "vault_token" "ssh_host" {
  # dynamically generate a token with constrained permisions for the host role.
  role_name = "host-vault-token-creds-role"

  policies = ["ssh_host"]

  renewable = false
  # ttl       = "120s"
  explicit_max_ttl = "120s"
  # period    = "600s"
}

data "template_file" "user_data_auth_client" {
  template = file("${path.module}/user-data-auth-ssh-host-vault-token.sh")

  vars = {
    consul_cluster_tag_key   = var.consul_cluster_tag_key
    consul_cluster_tag_value = var.consul_cluster_name
    vault_token              = vault_token.ssh_host.client_token
    aws_internal_domain               = var.aws_internal_domain
  }
}

locals {
  public_ip                     = element(concat(aws_eip.bastionip.*.public_ip, list("")), 0)
  private_ip                    = element(concat(aws_instance.bastion.*.private_ip, list("")), 0)
  id                            = element(concat(aws_instance.bastion.*.id, list("")), 0)
  bastion_security_group_id     = element(concat(aws_security_group.bastion.*.id, list("")), 0)
  bastion_vpn_security_group_id = element(concat(aws_security_group.bastion_vpn.*.id, list("")), 0)
  vpc_security_group_ids        = var.create_vpn ? [local.bastion_security_group_id, local.bastion_vpn_security_group_id] : [local.bastion_security_group_id]
  bastion_address               = var.route_public_domain_name ? "bastion.${var.public_domain_name}" : local.public_ip
}


# resource "null_resource" "provision_bastion" {
#   count    = var.create_vpc ? 1 : 0
#   depends_on = [
#     aws_instance.bastion,
#     aws_eip.bastionip,
#     aws_route53_record.bastion_record,
#   ]

#   triggers = {
#     instanceid = local.id
#     bastion_address = local.bastion_address
#   }

#   provisioner "local-exec" {
#     interpreter = ["/bin/bash", "-c"]
#     command = <<EOT
#       cd $TF_VAR_firehawk_path
#       echo "PWD: $PWD"
#       . scripts/exit_test.sh
#       export SHOWCOMMANDS=true; set -x
#       ansible-playbook -i "$TF_VAR_inventory" ansible/ssh-clean-public-host.yaml -v --extra-vars "variable_hosts=ansible_control variable_user=ec2-user public_ip=${local.public_ip} public_address=${local.bastion_address}"; exit_test
# EOT
#   }

#   provisioner "remote-exec" {
#     connection {
#       user        = "centos"
#       host        = local.public_ip
#       private_key = var.private_key
#       type        = "ssh"
#       timeout     = "10m"
#     }

#     inline = ["echo 'Instance is up.'"]
#   }

#   provisioner "local-exec" {
#     interpreter = ["/bin/bash", "-c"]
#     command = <<EOT
#       cd $TF_VAR_firehawk_path
#       echo "PWD: $PWD"
#       . scripts/exit_test.sh
#       export SHOWCOMMANDS=true; set -x
#       echo "inventory $TF_VAR_inventory/hosts"
#       cat $TF_VAR_inventory/hosts
#       ansible-playbook -i "$TF_VAR_inventory" ansible/ssh-add-public-host.yaml -v --extra-vars "variable_hosts=ansible_control variable_user=ec2-user public_ip=${local.public_ip} public_address=${local.bastion_address} bastion_address=${local.bastion_address} set_bastion=true"; exit_test
#       ansible-playbook -i "$TF_VAR_inventory" ansible/inventory-add.yaml -v --extra-vars "variable_user=ec2-user variable_group=ec2-user host_name=bastion host_ip=${local.public_ip} insert_ssh_key_string=ansible_ssh_private_key_file=$TF_VAR_aws_private_key_path"; exit_test
#       ansible-playbook -i "$TF_VAR_inventory" ansible/get-file.yaml -v --extra-vars "variable_user=ec2-user source=/var/log/messages dest=$TF_VAR_firehawk_path/tmp/log/cloud-init-output-bastion.log variable_user=centos variable_host=bastion"; exit_test
# EOT
#   }
# }

# locals {
#   bastion_dependency = element(concat(null_resource.provision_bastion.*.id, list("")), 0)
# }

variable "route_zone_id" {
}

variable "public_domain_name" {
}

resource "aws_route53_record" "bastion_record" {
  count   = var.route_public_domain_name && var.create_vpc ? 1 : 0
  zone_id = element(concat(list(var.route_zone_id), list("")), 0)
  name    = element(concat(list("bastion.${var.public_domain_name}"), list("")), 0)
  type    = "A"
  ttl     = 300
  records = [local.public_ip]
}

# resource "null_resource" "start-bastion" {
#   depends_on = [aws_instance.bastion]
#   count      = (! var.sleep && var.create_vpc) ? 1 : 0

#   provisioner "local-exec" {
#     interpreter = ["/bin/bash", "-c"]
#     command     = "sleep 10; aws ec2 start-instances --instance-ids ${local.id}"
#   }
# }

# resource "null_resource" "shutdown-bastion" {
#   depends_on = [aws_instance.bastion]
#   count      = var.sleep && var.create_vpc ? 1 : 0

#   provisioner "local-exec" {
#     interpreter = ["/bin/bash", "-c"]
#     command     = <<EOT
#       aws ec2 stop-instances --instance-ids ${local.id}
# EOT
#   }
# }

