variable "global_bucket_extension" {
  description = "The extension for cloud storage used to label your S3 storage buckets (eg: example.com, my-name-at-gmail.com). This can be any unique name (it must not be taken already, globally).  commonly, it is a domain name you own, or an abbreviated email adress.  No @ symbols are allowed. the global name will be used to create buckets in different environments.  a global bucket extension of example.com will result these buckets being created: dev.example.com, green.example.com, blue.example.com, main.example.com. See this doc for naming restrictions on s3 buckets - https://docs.aws.amazon.com/AmazonS3/latest/dev/BucketRestrictions.html"
  type = string
}

variable "vault_client_role_arns" {
  description = "The list of Role ARNS the provide access to the vault provisioner role"
  type = list(string)
}

variable "onsite_public_ip" {
  description = "The public ip address of your onsite location to enable access to security groups and openVPN."
  type = string
}

variable "onsite_private_subnet_cidr" {
  description = "The private subnet range that host IP's reside in onsite.  Usually provided by your router's DHCP range 192.168.x.0/24, where x is unique to your location."
  type = string
}
variable "restore_defaults" {
  description = "If true, will reset all values to system defaults"
  type        = bool
  default     = false
}

variable "init" {
  description = "If true, will only ensure paths exist."
  type        = bool
  default     = false
}

variable "aws_external_domain" {
  description = "The AWS external domain can be used for ssh certtificates, provided we always ensure to provide the CA cert to any host that wishes to connect. eg: ap-southeast-2.compute.amazonaws.com.  It is also possible to use your own domain, and recommended for produciton, provided you have enabled AWS access to control its name records."
  type        = string
}