variable "aws_key_name" {
  default = "main-deployment"
}

variable "aws_private_key_path" {
  description = "The private key path for the key used to ssh into the bastion for provisioning"
  type = string
  default = ""
}

variable "sleep" {
  description = "Sleep will disable the nat gateway and shutdown instances to save cost during idle time."
  type        = bool
  default     = false
}