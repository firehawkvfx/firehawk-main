# ENV VARS
# These secrets are defined as environment variables, or if running on an aws instance they do not need to be provided (they are provided by the instance role automatically instead)

# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY
# AWS_DEFAULT_REGION # this cen be set with:
# export AWS_DEFAULT_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/\(.*\)[a-z]/\1/'); echo $AWS_DEFAULT_REGION

variable "sleep" {
  description = "Sleep will disable the nat gateway and shutdown instances to save cost during idle time."
  type        = bool
  default     = false
}

variable "enable_vault" {
  description = "Deploy Hashicorp Vault into the VPC"
  type = bool
  default = true 
}

variable "bucket_extension" {
  description = "The extension for cloud storage used to label your S3 storage buckets (eg: example.com, my-name-at-gmail.com). This can be any unique name (it must not be taken already, globally).  commonly, it is a domain name you own, or an abbreviated email adress.  No @ symbols are allowed. See this doc for naming restrictions on s3 buckets - https://docs.aws.amazon.com/AmazonS3/latest/dev/BucketRestrictions.html"
  type = string
}

variable "aws_private_key_path" {
  description = "The private key path for the key used to ssh into the bastion for provisioning"
  type = string
  default = ""
}

variable "remote_ip_cidr" {
  description = "The public IP of the host used to ssh to the bastion, this may also potentially be a cloud 9 host.."
  type = string
}

variable "remote_cloud_private_ip_cidr" {
  description = "The remote private address that will connect to the bastion instance and other public instances.  This is used to limit inbound access to public facing hosts like the VPN from your site's public IP."
  type        = string
  default     = null
}

variable "remote_cloud_public_ip_cidr" {
  description = "The remote public address that will connect to the bastion instance and other public instances.  This is used to limit inbound access to public facing hosts like the VPN from your site's public IP."
  type        = string
  default     = null
}

variable "create_bastion_graphical" {
  description = "Creates a graphical bastion host for vault configuration."
  type = bool
  default = true
}

variable "remote_ip_graphical_cidr" {
  description = "The public IP of the host used to connect to the graphical bastion."
  type = string
}

variable "vault_consul_ami_id" {
  description = "The ID of the AMI to run in the vault cluster. This should be an AMI built from the Packer template under examples/vault-consul-ami/vault-consul.json. If no AMI is specified, the template will 'just work' by using the example public AMIs. WARNING! Do not use the example AMIs in a production setting!"
  type        = string
  default     = null
}

variable "bastion_ami_id" {
  description = "The prebuilt AMI for the bastion host. This should be a private ami you have build with packer from firehawk-main/modules/terraform-aws-vault/examples/bastion-ami."
  type = string
  default = null
}

variable "bastion_graphical_ami_id" {
  description = "The prebuilt AMI for the bastion host. This should be a private ami you have build with packer from firehawk-main/modules/terraform-aws-vault/examples/nice-dcv-ami."
  type = string
  default = null
}

variable "create_key_pair" {
  description = "Controls if key pair should be created"
  type        = bool
  default     = true
}