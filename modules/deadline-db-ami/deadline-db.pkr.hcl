# This file was autogenerated by the BETA 'packer hcl2_upgrade' command. We
# recommend double checking that everything is correct before going forward. We
# also recommend treating this file as disposable. The HCL2 blocks in this
# file can be moved to other files. For example, the variable blocks could be
# moved to their own 'variables.pkr.hcl' file, etc. Those files need to be
# suffixed with '.pkr.hcl' to be visible to Packer. To use multiple files at
# once they also need to be in the same folder. 'packer inspect folder/'
# will describe to you what is in that folder.

# All generated input variables will be of 'string' type as this is how Packer JSON
# views them; you can change their type later on. Read the variables type
# constraints documentation
# https://www.packer.io/docs/from-1.5/variables#type-constraints for more info.
variable "aws_region" {
  type = string
  default = null
}

variable "bastion_ubuntu18_ami" {
  type = string
}

variable "ca_public_key_path" {
  type    = string
  default = "/home/ec2-user/.ssh/tls/ca.crt.pem"
}

variable "install_auth_signing_script" {
  type    = string
  default = "true"
}

variable "resourcetier" {
  type    = string
}

locals {
  timestamp    = regex_replace(timestamp(), "[- TZ:]", "")
  template_dir = path.root
  bucket_extension = vault("/${var.resourcetier}/data/aws/bucket_extension", "value") # vault refs in packer use the api path, not the cli path
  deadline_version = vault("/${var.resourcetier}/data/deadline/deadline_version", "value")
  syscontrol_gid = vault("/${var.resourcetier}/data/system/syscontrol_gid", "value")
  deployuser_uid = vault("/${var.resourcetier}/data/system/deployuser_uid", "value")
  installers_bucket = vault("/main/data/aws/installers_bucket", "value")
}

source "amazon-ebs" "ubuntu18-ami" {
  ami_description = "An Ubuntu 18.04 AMI containing a Deadline DB server."
  ami_name        = "firehawk-deadlinedb-ubuntu18-${local.timestamp}-{{uuid}}"
  instance_type   = "t2.micro"
  region          = "${var.aws_region}"
  source_ami      = "${var.bastion_ubuntu18_ami}"
  ssh_username    = "ubuntu"
  # assume_role { # Since we need to read files from s3, we require a role with read access.
  #     role_arn     = "arn:aws:iam::972620357255:role/S3-Admin-S3" # This needs to be replaced with a terraform output
  #     session_name = "SESSION_NAME"
  #     external_id  = "EXTERNAL_ID"
  # }
}

build {
  sources = [
    "source.amazon-ebs.ubuntu18-ami"
    ]

  provisioner "ansible" {
    playbook_file = "./ansible/newuser_deadlineuser.yaml"
    extra_arguments = [
      "-v",
      "--extra-vars",
      "user_deadlineuser_name=ubuntu variable_host=default variable_connect_as_user=ubuntu variable_user=deployuser variable_uid=${local.deployuser_uid} delegate_host=localhost syscontrol_gid=${local.syscontrol_gid}"
    ]
    collections_path = "./ansible/collections"
    roles_path = "./ansible/roles"
    galaxy_file = "./requirements.yml"
  }

# ansible-playbook -i "$TF_VAR_inventory" ansible/newuser_deadlineuser.yaml -v --extra-vars "variable_host=role_softnas variable_connect_as_user=$TF_VAR_softnas_ssh_user variable_user=deployuser variable_uid=$TF_VAR_deployuser_uid"; exit_test
# ansible-playbook -i "$TF_VAR_inventory" ansible/newuser_deadlineuser.yaml -v --extra-vars "variable_host=role_softnas variable_connect_as_user=$TF_VAR_softnas_ssh_user variable_user=deadlineuser"; exit_test

  # provisioner "ansible" {
  #   playbook_file = "./ansible/add_user_to_group.yaml"
  #   extra_arguments = [
  #     "-v",
  #     "--extra-vars",
  #     "user_deadlineuser_name=ubuntu variable_host=default variable_connect_as_user=ubuntu variable_user=ubuntu delegate_host=localhost syscontrol_gid=${var.syscontrol_gid}"
  #   ]
  #   collections_path = "./ansible/collections"
  #   roles_path = "./ansible/roles"
  #   galaxy_file = "./requirements.yml"
  # }

# ansible-playbook -i "$TF_VAR_inventory" ansible/add_user_to_group.yaml -v --extra-vars "variable_host=firehawkgateway variable_connect_as_user=deployuser variable_user=deployuser variable_uid=$TF_VAR_deployuser_uid"; exit_test
  
  # provisioner "ansible" {
  #   playbook_file = "./ansible/deadline-db-install.yaml"
  #   extra_arguments = [
  #     "-v",
  #     "--extra-vars",
  #     "user_deadlineuser_name=deployuser variable_host=default variable_connect_as_user=ubuntu delegate_host=localhost installers_bucket=${local.installers_bucket} deadline_version=${local.deadline_version} reinstallation=false"
  #   ]
  #   collections_path = "./ansible/collections"
  #   roles_path = "./ansible/roles"
  #   galaxy_file = "./requirements.yml"
  # }

  post-processor "manifest" {
      output = "${local.template_dir}/manifest.json"
      strip_path = true
      custom_data = {
        timestamp = "${local.timestamp}"
      }
  }
}