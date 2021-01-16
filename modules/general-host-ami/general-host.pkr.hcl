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

variable "resourcetier" {
  type    = string
}

variable "consul_download_url" {
  type    = string
  default = ""
}

variable "consul_module_version" {
  type    = string
  default = "v0.8.0"
}

variable "consul_version" {
  type    = string
  default = "1.8.4"
}

variable "install_auth_signing_script" {
  type    = string
  default = "true"
}

variable "vault_download_url" {
  type    = string
  default = ""
}

variable "vault_version" {
  type    = string
  default = "1.5.5"
}

variable "consul_cluster_tag_key" {
  type = string
}

variable "consul_cluster_tag_value" {
  type = string
}

locals {
  timestamp    = regex_replace(timestamp(), "[- TZ:]", "")
  template_dir = path.root
}

source "amazon-ebs" "general-host-ubuntu18-ami" {
  ami_description = "An Ubuntu 18.04 AMI containing a Deadline DB server."
  ami_name        = "firehawk-general-host-vault-client-ubuntu18-${local.timestamp}-{{uuid}}"
  instance_type   = "t2.micro"
  region          = "${var.aws_region}"
  iam_instance_profile = "provisioner_instance_role_pipeid0"
  source_ami      = "${var.bastion_ubuntu18_ami}"
  ssh_username    = "ubuntu"
}

# source "amazon-ebs" "openvpn-server-ami" { # Open vpn server requires vault and consul, so we build it here as well.
#   ami_description = "An Open VPN Access Server AMI configured for Firehawk"
#   ami_name        = "firehawk-openvpn-server-base-${local.timestamp}-{{uuid}}"
#   instance_type   = "t2.micro"
#   region          = "${var.aws_region}"
#   # user_data = "admin_user=openvpnas; admin_pw=openvpnas"
#   user_data = <<EOF
# #! /bin/bash
# admin_user=openvpnas
# admin_pw=''
# EOF
#   # user_data_file  = "${local.template_dir}/openvpn_user_data.sh"
#   source_ami_filter {
#     filters = {
#       description  = "OpenVPN Access Server 2.8.3 publisher image from https://www.openvpn.net/."
#       product-code = "f2ew2wrz425a1jagnifd02u5t"
#     }
#     most_recent = true
#     owners      = ["679593333241"]
#   }
#   ssh_username = "openvpnas"
# }

build {
  sources = [
    "source.amazon-ebs.general-host-ubuntu18-ami"
    ]
  provisioner "shell" {
    inline         = ["echo 'init success'"]
    inline_shebang = "/bin/bash -e"
  }

  provisioner "shell" {
    inline         = ["sudo echo 'sudo echo test'"] # verify sudo is available
    inline_shebang = "/bin/bash -e"
  }

  provisioner "shell" {
    inline         = [
        "unset HISTFILE",
        "history -cw",
        "echo === Waiting for Cloud-Init ===",
        "timeout 180 /bin/bash -c 'until stat /var/lib/cloud/instance/boot-finished &>/dev/null; do echo waiting...; sleep 6; done'",
        "echo === System Packages ===",
        "echo 'connected success'",
        "sudo systemd-run --property='After=apt-daily.service apt-daily-upgrade.service' --wait /bin/true; echo \"exit $?\""
        ]
    environment_vars = ["DEBIAN_FRONTEND=noninteractive"]
    inline_shebang = "/bin/bash -e"
  }
  
  # provisioner "shell" {
  #   inline_shebang = "/bin/bash -e"
  #   only           = ["amazon-ebs.openvpn-server-ami"]
  #   environment_vars = ["DEBIAN_FRONTEND=noninteractive"]
  #   inline         = [
  #     "export SHOWCOMMANDS=true; set -x",
  #     "lsb_release -a",
  #     "ps aux | grep [a]pt",
  #     "sudo cat /etc/systemd/system.conf",
  #     "sudo chown openvpnas:openvpnas /home/openvpnas; echo \"exit $?\"",
  #     "echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections; echo \"exit $?\"",
  #     "ls -ltriah /var/cache/debconf/passwords.dat; echo \"exit $?\"",
  #     "ls -ltriah /var/cache/; echo \"exit $?\""
  #   ]
  # }

  # provisioner "shell" {
  #   inline_shebang = "/bin/bash -e"
  #   only           = ["amazon-ebs.openvpn-server-ami"]
  #   environment_vars = ["DEBIAN_FRONTEND=noninteractive"]
  #   valid_exit_codes = [0,1] # ignore exit code.  this requirement is a bug in the open vpn ami.
  #   inline         = [
  #     # "sudo apt -y install dialog || exit 0" # supressing exit code.
  #     "sudo apt -y install dialog; echo \"exit $?\"" # supressing exit code.
  #   ]
  # }

  # provisioner "shell" {
  #   inline_shebang = "/bin/bash -e"
  #   only           = ["amazon-ebs.openvpn-server-ami"]
  #   environment_vars = ["DEBIAN_FRONTEND=noninteractive"]
  #   inline         = [
  #     "DEBIAN_FRONTEND=noninteractive sudo apt-get install -y -q; echo \"exit $?\""
  #   ]
  # }

  # provisioner "shell" {
  #   inline_shebang = "/bin/bash -e"
  #   only           = ["amazon-ebs.openvpn-server-ami"]
  #   environment_vars = ["DEBIAN_FRONTEND=noninteractive"]
  #   valid_exit_codes = [0,1] # ignore exit code.
  #   inline         = [
  #     # "DEBIAN_FRONTEND=noninteractive sudo apt-get -y install dialog apt-utils", # may fix error with debconf: unable to initialize frontend: Dialog
  #     # "echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections", # may fix error with debconf: unable to initialize frontend: Dialog
  #     # "sudo apt-get install -y -q", # may fix error with debconf: unable to initialize frontend: Dialog
  #     # "sudo apt-get -y update",
  #     # "sudo chown openvpnas:openvpnas /home/openvpnas", # This must be a bug with 2.8.5 open vpn ami.
  #     "ls -ltriah /home; echo \"exit $?\"",
  #     "sudo fuser -v /var/cache/debconf/config.dat; echo \"exit $?\"" # get info if anything else has a lock on this file
  #   ]
  # }

  # provisioner "shell" {
  #   inline         = ["sudo systemd-run --property='After=apt-daily.service apt-daily-upgrade.service' --wait /bin/true"]
  #   inline_shebang = "/bin/bash -e"
  # }

  provisioner "shell" {
    inline_shebang = "/bin/bash -e"
    # only           = ["amazon-ebs.openvpn-server-ami"]
    environment_vars = ["DEBIAN_FRONTEND=noninteractive"]
    inline         = [
      "echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections", 
      "sudo apt-get install -y -q"
    ]
  }

  provisioner "shell" {
    inline_shebang = "/bin/bash -e"
    # only           = ["amazon-ebs.openvpn-server-ami"]
    environment_vars = ["DEBIAN_FRONTEND=noninteractive"]
    inline         = [
      "sudo apt-get -y update"
    ]
  }

  provisioner "shell" {
    inline_shebang = "/bin/bash -e"
    # only           = ["amazon-ebs.openvpn-server-ami"]
    environment_vars = ["DEBIAN_FRONTEND=noninteractive"]
    inline         = [ 
      "sudo apt-get install dpkg -y"
    ]
  }

  provisioner "shell" {
    inline_shebang = "/bin/bash -e"
    # only           = ["amazon-ebs.openvpn-server-ami"]
    environment_vars = ["DEBIAN_FRONTEND=noninteractive"]
    inline         = [ 
      "sudo apt-get -y install python3",
      "sudo apt-get -y install python-apt",
      "sudo apt install -y python3-pip",
      "python3 -m pip install --upgrade pip",
      "python3 -m pip install boto3",
      "python3 -m pip --version",
      "sudo apt-get install -y git",
      "echo '...Finished bootstrapping'"
    ]
  }

  provisioner "ansible" {
    extra_arguments = [
      "-v",
      "--extra-vars",
      "variable_host=default variable_connect_as_user=ubuntu variable_user=ubuntu variable_become_user=ubuntu delegate_host=localhost",
      "--skip-tags",
      "user_access"
    ]
    playbook_file = "./ansible/aws_cli_ec2_install.yaml"
    collections_path = "./ansible/collections"
    roles_path = "./ansible/roles"
    ansible_env_vars = [ "ANSIBLE_CONFIG=ansible/ansible.cfg" ]
    galaxy_file = "./requirements.yml"
    only           = ["amazon-ebs.general-host-ubuntu18-ami"]
  }

  # provisioner "ansible" {
  #   playbook_file = "./ansible/aws_cli_ec2_install.yaml"
  #   extra_arguments = [
  #     "-v",
  #     "--extra-vars",
  #     "variable_host=default variable_connect_as_user=openvpnas variable_user=openvpnas variable_become_user=openvpnas delegate_host=localhost",
  #     "--skip-tags",
  #     "user_access"
  #   ]
  #   collections_path = "./ansible/collections"
  #   roles_path = "./ansible/roles"
  #   ansible_env_vars = [ "ANSIBLE_CONFIG=ansible/ansible.cfg" ]
  #   galaxy_file = "./requirements.yml"
  #   only           = ["amazon-ebs.openvpn-server-ami"]
  # }

  provisioner "shell" {
    inline = ["mkdir -p /tmp/terraform-aws-vault/modules"]
  }

  provisioner "file" {
    destination = "/tmp/terraform-aws-vault/modules"
    source      = "${local.template_dir}/../terraform-aws-vault/modules/"
  }

  provisioner "file" {
    destination = "/tmp/sign-request.py"
    source      = "${local.template_dir}/auth/sign-request.py"
  }
  provisioner "file" {
    destination = "/tmp/ca.crt.pem"
    source      = "${var.ca_public_key_path}"
  }

  ### This block will install Vault and Consul Agent

  provisioner "shell" { # Vault client probably wont be installed on bastions in future, but most hosts that will authenticate will require it.
    inline = [
      "if test -n '${var.vault_download_url}'; then",
      " /tmp/terraform-aws-vault/modules/install-vault/install-vault --download-url ${var.vault_download_url};",
      "else",
      " /tmp/terraform-aws-vault/modules/install-vault/install-vault --version ${var.vault_version};",
      "fi"
      ]
  }

  provisioner "shell" {
    inline         = [
      "sudo apt-get install -y git",
      "if [[ '${var.install_auth_signing_script}' == 'true' ]]; then",
      "sudo apt-get install -y python-pip",
      "LC_ALL=C && sudo pip install boto3",
      "fi"]
    inline_shebang = "/bin/bash -e"
    # only           = ["amazon-ebs.ubuntu16-ami", "amazon-ebs.ubuntu18-ami"]
  }

  provisioner "shell" {
    inline = [
      "git clone --branch ${var.consul_module_version} https://github.com/hashicorp/terraform-aws-consul.git /tmp/terraform-aws-consul",
      "if test -n \"${var.consul_download_url}\"; then",
      " /tmp/terraform-aws-consul/modules/install-consul/install-consul --download-url ${var.consul_download_url};",
      "else",
      " /tmp/terraform-aws-consul/modules/install-consul/install-consul --version ${var.consul_version};",
      "fi"]
  }

  # provisioner "file" { # the default resolv conf may not be configured correctly since it has a ref to non FQDN hostname.  this may break again if it is being misconfigured on boot which has been observed in ubuntu 18
  #   destination = "/tmp/resolv.conf"
  #   source      = "${local.template_dir}/resolv.conf"
  # }

  # provisioner "file" { # the default resolv conf may not be configured correctly since it has a ref to non FQDN hostname.  this may break again if it is being misconfigured on boot which has been observed in ubuntu 18
  #   destination = "/tmp/ubuntu.json"
  #   source      = "${local.template_dir}/ubuntu.json"
  # }

  provisioner "shell" { # Generate certificates with vault.
    inline = [
      # "set -x; sudo mv /tmp/ubuntu.json /opt/consul/config", # ubuntu requires a fix for dns to forward lookups outside of consul domain to 127.0.0.53
      "set -x; sudo cat /etc/resolv.conf",
      # "sudo sed -i \"s/#DNS=/DNS=127.0.0.1 127.0.0.53/g\" /etc/systemd/resolved.conf", # we do this ahead of the script. needed for ubuntu.
      # "sudo sed -i \"s/#Domains=/Domains=~service.consul./g\" /etc/systemd/resolved.conf", # we do this ahead of the script. needed for ubuntu.
      # "sudo sed -i \"s/#FallbackDNS=/FallbackDNS=127.0.0.53/g\" /etc/systemd/resolved.conf",
      # "sudo sed -i \"s/#DNS=/DNS=127.0.0.1 127.0.0.53/g\" /etc/systemd/resolved.conf", # we do this ahead of the script. needed for ubuntu.
      "sudo sed -i \"s/#Domains=/Domains=~service.consul./g\" /etc/systemd/resolved.conf", # we do this ahead of the script. needed for ubuntu.
      # "sudo sed -i \"s/#FallbackDNS=/FallbackDNS=127.0.0.53/g\" /etc/systemd/resolved.conf",
      "set -x; sudo cat /etc/systemd/resolved.conf",
      "set -x; /tmp/terraform-aws-consul/modules/setup-systemd-resolved/setup-systemd-resolved",
      "set -x; sudo cat /etc/systemd/resolved.conf",
      "set -x; sudo systemctl daemon-reload",
      "set -x; sudo systemctl restart systemd-resolved",
      
      "set -x; sudo cat /etc/systemd/resolved.conf",
      "set -x; sudo cat /etc/resolv.conf",

      "set -x; sudo /opt/consul/bin/run-consul --client --cluster-tag-key \"${var.consul_cluster_tag_key}\" --cluster-tag-value \"${var.consul_cluster_tag_value}\"", # this is normally done with user data but dont for convenience here
      "set -x; sudo cat /etc/resolv.conf",

      "set -x; sudo systemctl daemon-reload",
      "set -x; sudo systemctl restart systemd-resolved",

      "set -x; consul members list",
      "set -x; dig $(hostname) | awk '/^;; ANSWER SECTION:$/ { getline ; print $5 ; exit }'", # check localhost resolve's
      "set -x; dig @127.0.0.1 vault.service.consul | awk '/^;; ANSWER SECTION:$/ { getline ; print $5 ; exit }'", # check consul will resolve vault
      "set -x; dig @localhost vault.service.consul | awk '/^;; ANSWER SECTION:$/ { getline ; print $5 ; exit }'", # check local host will resolve vault
      "set -x; dig vault.service.consul | awk '/^;; ANSWER SECTION:$/ { getline ; print $5 ; exit }'", # check default lookup will resolve vault
      "echo '\nis the host name in /etc/hostname and /etc/hosts ?'",
      "sudo cat /etc/hostname",
      "sudo cat /etc/hosts"
      ]
  }

  # provisioner "shell" {
  #   inline = [
  #     "set -x; sudo mv /tmp/ubuntu.json /opt/consul/config", # ubuntu requires a fix for dns
  #     "set -x; sudo mv /tmp/resolv.conf /run/systemd/resolve/resolv.conf",
  #     "set -x; sudo cat /etc/resolv.conf",
  #     "set -x; sudo cat /run/systemd/resolve/resolv.conf",
  #     "/tmp/terraform-aws-consul/modules/setup-systemd-resolved/setup-systemd-resolved",
  #     "set -x; sudo cat /run/systemd/resolve/resolv.conf",
  #     "sudo ls -ltriah /etc/resolv.conf",
  #     "sudo unlink /etc/resolv.conf",
  #     "sudo ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf", # resolve.conf initial link isn't configured with a sane default.
  #     "set -x; sudo cat /etc/resolv.conf",
  #     "sudo systemctl daemon-reload",
  #     "echo 'is the host name in /etc/hostname and /etc/hosts ?'",
  #     "sudo cat /etc/hostname",
  #     "sudo cat /etc/hosts"
  #     ]
  #   # only   = ["amazon-ebs.ubuntu18-ami"]
  # }

  post-processor "manifest" {
      output = "${local.template_dir}/manifest.json"
      strip_path = true
      custom_data = {
        timestamp = "${local.timestamp}"
      }
  }
}