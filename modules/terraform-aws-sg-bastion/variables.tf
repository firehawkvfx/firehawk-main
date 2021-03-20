
variable "name" {
  description = "The name used to define resources in this module"
  type        = string
  default     = "bastion"
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

variable "permitted_cidr_list" {
  description = "The list of remote CIDR blocks that will be able to access the host."
  type        = list(string)
}