variable "aws_region" {
  type = string
  default = null
}

locals {
  timestamp    = regex_replace(timestamp(), "[- TZ:]", "")
}

source "amazon-ebs" "openvpn-server-ami" { # Open vpn server requires vault and consul, so we build it here as well.
  ami_description = "An Open VPN Access Server AMI configured for Firehawk"
  ami_name        = "firehawk-openvpn-server-base-${local.timestamp}-{{uuid}}"
  instance_type   = "t2.micro"
  region          = "${var.aws_region}"
  source_ami_filter {
    filters = {
      description  = "OpenVPN Access Server 2.8.3 publisher image from https://www.openvpn.net/."
      product-code = "f2ew2wrz425a1jagnifd02u5t"
    }
    most_recent = true
    owners      = ["679593333241"]
  }
  ssh_username = "openvpnas"
}

build {
  sources = [
    "source.amazon-ebs.openvpn-server-ami"
    ]
  provisioner "shell" {
    inline         = ["echo 'connected success'"]
  }
}