variable "aws_key_name" {
  default = "main-deployment"
}

variable "bastion_ami_id" {
  description = "The prebuilt AMI for the bastion host. This should be a private ami you have build with packer."
  type = string
}

variable "sleep" {
  description = "Sleep will disable the nat gateway and shutdown instances to save cost during idle time."
  type        = bool
  default     = false
}

variable "resourcetier" {
    description = "The resource tier speicifies a unique name for a resource based on the environment.  eg:  dev, green, blue, main."
    type = string
    default = "main"
}

variable "pipelineid" {
    description = "The pipelineid variable can be used to uniquely specify and identify resource names for a given deployment.  The pipeline ID could be set to a job ID in CI software for example.  The default of 0 is fine if no more than one concurrent deployment run will occur."
    type = string
    default = "0"
}

variable "route_public_domain_name" {
  description = "Defines if a public DNS name is to be used"
  type        = bool
  default     = false
}

variable "remote_cloud_ip_cidr" {
  description = "The remote cloud IP address that will access the bastion (cloud 9)"
  type = string
}