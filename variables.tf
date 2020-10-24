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

variable "vault_public_key" {
  description = "The public key of the host used to ssh into the vault cluster"
  type = string
  default = ""
}

variable "remote_ip_cidr" {
  description = "The public IP of the host used to ssh to the bastion."
  type = string
  default = ""
}