
variable "name" {
  description = "The name used to define resources in this module"
  type        = string
  default     = "bastion"
}
variable "common_tags" {
  description = "A map of common tags to assign to the resources created by this module"
  type        = map(string)
  default     = {}
}
variable "onsite_public_ip" {
  description = "The public ip address of your onsite location to enable access to security groups and openVPN."
  type        = string
}
variable "combined_vpcs_cidr" {
  description = "Terraform will automatically configure multiple VPCs and subnets within this CIDR range for any resourcetier ( dev / green / blue / main )."
  type        = string
}
variable "vpn_cidr" {
  description = "The CIDR range that the vpn will assign using DHCP.  These are virtual addresses for routing traffic."
  type        = string
}
variable "onsite_private_subnet_cidr" {
  description = "The subnet CIDR Range of your onsite private subnet. This is also the subnet where your VPN client resides in. eg: 192.168.1.0/24"
  type        = string
}
variable "deployer_ip_cidr" {
  description = "The public IP of the host used to ssh, this may also potentially be a cloud 9 host.."
  type        = string
}
