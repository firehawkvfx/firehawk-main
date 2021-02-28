variable "name" {
  description = "The name used to define resources in this module"
  type        = string
  default     = "bastion"
}
variable "bastion_ami_id" {
  description = "The prebuilt AMI for the bastion host. This should be a private ami you have build with packer."
  type        = string
}
variable "create_vpc" {
  description = "If used in a submodule, it is possible to selectively destroy resources by setting this to false."
  type        = bool
  default     = true
}
variable "vpc_id" {
  description = "The ID of the VPC to deploy into. Leave an empty string to use the Default VPC in this region."
  type        = string
  default     = null
}
variable "vpc_cidr" {
  description = "The CIDR block that contains all subnets within the VPC."
  type        = string
}

variable "common_tags" {
  description = "A map of common tags to assign to the resources created by this module"
  type        = map(string)
  default     = {}
}
variable "route_zone_id" {
  description = "(Optional) The Route53 Zone ID if using a public DNS"
  type        = string
  default     = null
}
variable "public_domain_name" {
  description = "The public DNS name to be used"
  type        = string
  default     = null
}
variable "remote_ip_cidr_list" {
  description = "The list of remote CIDR blocks that will be able to access the host."
  type        = list(string)
}
variable "route_public_domain_name" {
  description = "Defines if a public DNS name is to be used"
  type        = bool
  default     = false
}

variable "public_subnet_ids" {
  description = "The list of public subnets to deploy into.  Currently only the first subnet is used."
  type        = list(string)
  default     = []
}
# variable "aws_key_name" {
#   description = "The name of the AWS PEM key for access to the VPN instance"
#   type        = string
#   default     = null
# }
variable "instance_type" {
  description = "The AWS instance type to use."
  type        = string
  default     = "t3.micro"
}
variable "node_skip_update" {
  description = "Skipping node updates is not recommended, but it is available to speed up deployment tests when diagnosing problems"
  type        = bool
  default     = false
}
variable "consul_cluster_name" {
  description = "What to name the Consul server cluster and all of its associated resources"
  type        = string
  default     = "consul-example"
}
variable "consul_cluster_tag_key" {
  description = "The tag the Consul EC2 Instances will look for to automatically discover each other and form a cluster."
  type        = string
  default     = "consul-servers"
}
variable "aws_internal_domain" {
  description = "The domain used to resolve internal FQDN hostnames."
  type        = string
}
variable "aws_external_domain" {
  description = "The domain used to resolve external FQDN hostnames.  Since we always provide the CA for externals connections, the default for public ec2 instances is acceptable, but in production it is best configure it with your own domain."
  type        = string
}
