# Defines the default values to initialise vault vars with.

locals {
  defaults = tomap( {
    "deadline/deadline_version" = {
      "name" = "deadline_version",
      "description" = "The version of the deadline installer.",
      "default" = "10.1.9.2",
      "example_1" = "10.1.9.2",
    },
    "ansible/selected_ansible_version" = {
      "name" = "selected_ansible_version"
      "description" = "The version to use for ansible.  Can be 'latest', or a specific version.  due to a bug with pip and ansible we can have pip permissions and authentication issues when not using latest. This is because pip installs the version instead of apt-get when using a specific version instead of latest.  Resolution by using virtualenv will be required to resolve.",
      "default" = "latest",
      "example_1" = "latest",
      "example_2" = "2.9.2"
    },
    "system/deployuser_uid" = {
      "name" = "deployuser_uid",
      "description": "The user id (UID) for the deployuser utilised for provisioning",
      "default": "9004",
      "example_1": "9004",
    },
    "system/deadlineuser_uid" = {
      "name" = "deadlineuser_uid",
      "description": "The user id (UID) for the deadlineuser utilised for rendering",
      "default": "9001",
      "example_1": "9001",
    },
    "system/syscontrol_gid" = {
      "name" = "syscontrol_gid",
      "description": "The group id (GID) for the syscontrol group",
      "default": "9003",
      "example_1": "9003",
    },
    "network/onsite_private_subnet_cidr" = {
      "name" = "onsite_private_subnet_cidr",
      "description": "This is the IP range of your subnet onsite that the firehawkserver vm will reside in, and that other onsite nodes reside in.  The below example (in CIDR notation) would denote the range 192.168.29.0 - 192.168.29.255",
      "default": var.onsite_private_subnet_cidr,
      "example_1": "192.168.29.0/24",
    },
    "network/onsite_public_ip" = {
      "name" = "onsite_public_ip",
      "description": "Your remote public IP address you will use to access the VPN / Bastion hosts from.",
      "default": var.onsite_public_ip,
      "example_1": "180.150.104.201",
    },
    "network/openvpn_admin_pw" = {
      "name" = "openvpn_admin_pw",
      "description": "The password for the admin to configure OpenVPN Access Server (at least 8 characters).",
      "default": "",
      "example_1": "MySecretAdminPassword",
    },
    "network/openvpn_user_pw" = {
      "name" = "openvpn_user_pw",
      "description": "The password for the user to establish a vpn connection (at least 8 characters).",
      "default": "",
      "example_1": "MySecretUserPassword",
    }    
  } )
  dev = merge(local.defaults, tomap( {
    "aws/bucket_extension" = {
      "name" = "bucket_extension",
      "description": "The extension for cloud storage used to label your S3 storage buckets.  MUST BE UNIQUE TO THIS RESOURCE TIER (DEV, GREEN, BLUE). This can be any unique name (it must not be taken already, globally).  commonly, it is a domain name you own, or an abbreviated email adress.  No @ symbols are allowed. See this doc for naming restrictions on s3 buckets - https://docs.aws.amazon.com/AmazonS3/latest/dev/BucketRestrictions.html",
      "default": "dev.${var.global_bucket_extension}",
      "example_1": "dev.example.com",
      "example_2": "green.example.com",
      "example_3": "dev-myemail-gmail-com"
    },
    "network/vpn_cidr" = {
      "name" = "vpn_cidr",
      "description": "Open VPN sets up DHCP in this range for every connection in the dev env to provide a unique ip on each side of the VPN for every system. Dont change this from the default for now. Reference for potential ranges https://www.arin.net/reference/research/statistics/address_filters/",
      "default": "172.17.232.0/24",
      "example_1": "172.17.232.0/24"
    },
    "network/vpc_cidr" = {
      "name" = "vpc_cidr",
      "description": "This is the IP range (CIDR notation) of your cloud subnet that all AWS private addresses will reside in.",
      "default": "10.1.0.0/16",
      "example_1": "10.1.0.0/16"
    },
    "network/private_subnet1" = {
      "name" = "private_subnet1",
      "description": "The IP range for private subnet 1 for workers.  This subnet is accessed via VPN or bastion hosts.",
      "default": "10.1.1.0/24",
      "example_1": "10.1.1.0/24"
    },
    "network/private_subnet2" = {
      "name" = "private_subnet2",
      "description": "The IP range for private subnet 2 for workers.  This subnet is accessed via VPN or bastion hosts.",
      "default": "10.1.2.0/24",
      "example_1": "10.1.2.0/24"
    },
    "network/public_subnet1" = {
      "name" = "private_subnet1",
      "description": "The IP range for public subnet 1 for public facing systems.  Examples are your VPN access server instance, or bastion host for provisioning other instances in the private network.",
      "default": "10.1.101.0/24",
      "example_1": "10.1.101.0/24"
    },
    "network/public_subnet2" = {
      "name" = "public_subnet2",
      "description": "The IP range for public subnet 2 for public facing systems.  Examples are your VPN access server instance, or bastion host for provisioning other instances in the private network.",
      "default": "10.1.102.0/24",
      "example_1": "10.1.102.0/24"
    },
    "network/private_domain" = {
      "name" = "private_domain",
      "description": "The private domain name for your hosts.  This is required for the host names and fsx storage in a private network.  Launched Infrastructure will switch between different domains depending on the resource environment for isolation.",
      "default": "dev.node.consul",
      "example_1": "dev.node.consul"
    }
  } ) )
  blue = merge(local.defaults, tomap( {
    "aws/bucket_extension" = {
      "name" = "bucket_extension",
      "description": "The extension for cloud storage used to label your S3 storage buckets.  MUST BE UNIQUE TO THIS RESOURCE TIER (DEV, GREEN, BLUE). This can be any unique name (it must not be taken already, globally).  commonly, it is a domain name you own, or an abbreviated email adress.  No @ symbols are allowed. See this doc for naming restrictions on s3 buckets - https://docs.aws.amazon.com/AmazonS3/latest/dev/BucketRestrictions.html",
      "default": "blue.${var.global_bucket_extension}",
      "example_1": "dev.example.com",
      "example_2": "green.example.com",
      "example_3": "dev-myemail-gmail-com"
    },
    "network/vpn_cidr" = {
      "name" = "vpn_cidr",
      "description": "Open VPN sets up DHCP in this range for every connection in the dev env to provide a unique ip on each side of the VPN for every system. Dont change this from the default for now. Reference for potential ranges https://www.arin.net/reference/research/statistics/address_filters/",
      "default": "172.18.232.0/24",
      "example_1": "172.18.232.0/24"
    },
    "network/vpc_cidr" = {
      "name" = "vpc_cidr",
      "description": "This is the IP range (CIDR notation) of your cloud subnet that all AWS private addresses will reside in.",
      "default": "10.2.0.0/16",
      "example_1": "10.2.0.0/16"
    },
    "network/private_subnet1" = {
      "name" = "private_subnet1",
      "description": "The IP range for private subnet 1 for workers.  This subnet is accessed via VPN or bastion hosts.",
      "default": "10.2.1.0/24",
      "example_1": "10.2.1.0/24"
    },
    "network/private_subnet2" = {
      "name" = "private_subnet2",
      "description": "The IP range for private subnet 2 for workers.  This subnet is accessed via VPN or bastion hosts.",
      "default": "10.2.2.0/24",
      "example_1": "10.2.2.0/24"
    },
    "network/public_subnet1" = {
      "name" = "private_subnet1",
      "description": "The IP range for public subnet 1 for public facing systems.  Examples are your VPN access server instance, or bastion host for provisioning other instances in the private network.",
      "default": "10.2.101.0/24",
      "example_1": "10.2.101.0/24"
    },
    "network/public_subnet2" = {
      "name" = "public_subnet2",
      "description": "The IP range for public subnet 2 for public facing systems.  Examples are your VPN access server instance, or bastion host for provisioning other instances in the private network.",
      "default": "10.2.102.0/24",
      "example_1": "10.2.102.0/24"
    },
    "network/private_domain" = {
      "name" = "private_domain",
      "description": "The private domain name for your hosts.  This is required for the host names and fsx storage in a private network.  Launched Infrastructure will switch between different domains depending on the resource environment for isolation.",
      "default": "blue.node.consul",
      "example_1": "blue.node.consul"
    }
  } ) )
  green = merge(local.defaults, tomap( {
    "aws/bucket_extension" = {
      "name" = "bucket_extension",
      "description": "The extension for cloud storage used to label your S3 storage buckets.  MUST BE UNIQUE TO THIS RESOURCE TIER (DEV, GREEN, BLUE). This can be any unique name (it must not be taken already, globally).  commonly, it is a domain name you own, or an abbreviated email adress.  No @ symbols are allowed. See this doc for naming restrictions on s3 buckets - https://docs.aws.amazon.com/AmazonS3/latest/dev/BucketRestrictions.html",
      "default": "green.${var.global_bucket_extension}",
      "example_1": "dev.example.com",
      "example_2": "green.example.com",
      "example_3": "dev-myemail-gmail-com"
    },
    "network/vpn_cidr" = {
      "name" = "vpn_cidr",
      "description": "Open VPN sets up DHCP in this range for every connection in the dev env to provide a unique ip on each side of the VPN for every system. Dont change this from the default for now. Reference for potential ranges https://www.arin.net/reference/research/statistics/address_filters/",
      "default": "172.19.232.0/24",
      "example_1": "172.19.232.0/24"
    },
    "network/vpc_cidr" = {
      "name" = "vpc_cidr",
      "description": "This is the IP range (CIDR notation) of your cloud subnet that all AWS private addresses will reside in.",
      "default": "10.3.0.0/16",
      "example_1": "10.3.0.0/16"
    },
    "network/private_subnet1" = {
      "name" = "private_subnet1",
      "description": "The IP range for private subnet 1 for workers.  This subnet is accessed via VPN or bastion hosts.",
      "default": "10.3.1.0/24",
      "example_1": "10.3.1.0/24"
    },
    "network/private_subnet2" = {
      "name" = "private_subnet2",
      "description": "The IP range for private subnet 2 for workers.  This subnet is accessed via VPN or bastion hosts.",
      "default": "10.3.2.0/24",
      "example_1": "10.3.2.0/24"
    },
    "network/public_subnet1" = {
      "name" = "private_subnet1",
      "description": "The IP range for public subnet 1 for public facing systems.  Examples are your VPN access server instance, or bastion host for provisioning other instances in the private network.",
      "default": "10.3.101.0/24",
      "example_1": "10.3.101.0/24"
    },
    "network/public_subnet2" = {
      "name" = "public_subnet2",
      "description": "The IP range for public subnet 2 for public facing systems.  Examples are your VPN access server instance, or bastion host for provisioning other instances in the private network.",
      "default": "10.3.102.0/24",
      "example_1": "10.3.102.0/24"
    },
    "network/private_domain" = {
      "name" = "private_domain",
      "description": "The private domain name for your hosts.  This is required for the host names and fsx storage in a private network.  Launched Infrastructure will switch between different domains depending on the resource environment for isolation.",
      "default": "green.node.consul",
      "example_1": "green.node.consul"
    }
  } ) )
  main = merge(local.defaults, tomap( {
    "aws/installers_bucket" = {
      "name" = "installers_bucket",
      "description" = "The S3 bucket name in the main account to store installers and software for all your AWS accounts.  The name must be globally unique.",
      "default" = "software.main.${var.global_bucket_extension}",
      "example_1" = "software.main.example.com",
      "example_3": "software-main-myemail-gmail-com"
    },
    "network/vpn_cidr" = {
      "name" = "vpn_cidr",
      "description": "Open VPN sets up DHCP in this range for every connection in the dev env to provide a unique ip on each side of the VPN for every system. Dont change this from the default for now. Reference for potential ranges https://www.arin.net/reference/research/statistics/address_filters/",
      "default": "172.20.232.0/24",
      "example_1": "172.20.232.0/24"
    },
    "network/vpc_cidr" = {
      "name" = "vpc_cidr",
      "description": "This is the IP range (CIDR notation) of your cloud subnet that all AWS private addresses will reside in.",
      "default": "10.4.0.0/16",
      "example_1": "10.4.0.0/16"
    },
    "network/private_subnet1" = {
      "name" = "private_subnet1",
      "description": "The IP range for private subnet 1 for workers.  This subnet is accessed via VPN or bastion hosts.",
      "default": "10.4.1.0/24",
      "example_1": "10.4.1.0/24"
    },
    "network/private_subnet2" = {
      "name" = "private_subnet2",
      "description": "The IP range for private subnet 2 for workers.  This subnet is accessed via VPN or bastion hosts.",
      "default": "10.4.2.0/24",
      "example_1": "10.4.2.0/24"
    },
    "network/public_subnet1" = {
      "name" = "private_subnet1",
      "description": "The IP range for public subnet 1 for public facing systems.  Examples are your VPN access server instance, or bastion host for provisioning other instances in the private network.",
      "default": "10.4.101.0/24",
      "example_1": "10.4.101.0/24"
    },
    "network/public_subnet2" = {
      "name" = "public_subnet2",
      "description": "The IP range for public subnet 2 for public facing systems.  Examples are your VPN access server instance, or bastion host for provisioning other instances in the private network.",
      "default": "10.4.102.0/24",
      "example_1": "10.4.102.0/24"
    },
    "network/private_domain" = {
      "name" = "private_domain",
      "description": "The private domain name for your hosts.  This is required for the host names and fsx storage in a private network.  Launched Infrastructure will switch between different domains depending on the resource environment for isolation.",
      "default": "main.node.consul",
      "example_1": "main.node.consul"
    }
  } ) )
}