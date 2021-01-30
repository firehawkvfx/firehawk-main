variable "name" {
  default = "bastion"
}

variable "bastion_ami_id" {
  description = "The prebuilt AMI for the bastion host. This should be a private ami you have build with packer."
  type = string
  default = null
}

variable "create_vpc" {
  default = true
}

variable "create_vpn" {
  default = false
}

variable "vpc_id" {
}

variable "vpc_cidr" {
}

# remote_ip_cidr is the ip address of the remote host / user intending to connect over vpn. eg '197.125.62.53/32'
#example "125.254.24.255/32"
variable "vpn_cidr" {
}

variable "remote_ip_cidr" {
}

variable "public_subnets_cidr_blocks" {
}

variable "route_public_domain_name" {}

# variable "private_subnets_cidr_blocks" {
# }

variable "remote_subnet_cidr" {
}

# examples ["subnet-0a7554f56af4d6d0a", "subnet-0257c7f8b1d68b6e4"]
variable "public_subnet_ids" {
  default = []
}

variable "aws_key_name" {
}

#this ami id is for southeast-ap-2 sydney only.  todo - changes will need to be made to pull a list of ami's

variable "ami_map" {
  type = map(string)

  default = {
    ap-southeast-2 = "ami-d8c21dba"
  }
}

variable "instance_type" {
  default = "t3.micro"
}

variable "user" {
  default = "centos"
}

variable "sleep" {
  default = false
}

variable "node_skip_update" {
  description = "Skipping node updates is not recommended, but it is available to speed up deployment tests when diagnosing problems"
  type        = bool
  default     = false
}
