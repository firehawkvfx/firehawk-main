variable "aws_key_name" {
  type = string
  default = null
}

variable "vault_client_ami_id" {
  description = "The prebuilt AMI for the vault client host. This should be a private ami you have build with packer."
  type        = string
}

variable "sleep" {
  description = "Sleep will disable the nat gateway and shutdown instances to save cost during idle time."
  type        = bool
  default     = false
}

variable "resourcetier" {
  description = "The resource tier speicifies a unique name for a resource based on the environment.  eg:  dev, green, blue, main."
  type        = string
}

variable "pipelineid" {
  description = "The pipelineid variable can be used to uniquely specify and identify resource names for a given deployment.  The pipeline ID could be set to a job ID in CI software for example.  The default of 0 is fine if no more than one concurrent deployment run will occur."
  type        = string
}

# variable "route_public_domain_name" {
#   description = "Defines if a public DNS name is to be used"
#   type        = bool
#   default     = false
# }

variable "remote_cloud_public_ip_cidr" {
  description = "The remote cloud IP public address that will access the vault client (cloud 9)"
  type        = string
}

variable "remote_cloud_private_ip_cidr" {
  description = "The remote cloud private IP address that will access the vault client (cloud 9)"
  type        = string
}

variable "aws_internal_domain" {
  description = "The domain used to resolve FQDN hostnames."
  type        = string
}

# variable "aws_external_domain" {
#   description = "The domain used to resolve external FQDN hostnames.  Since we always provide the CA for externals connections, the default for public ec2 instances is acceptable, but in production it is best configure it with your own domain."
#   type        = string
# }

variable "bastion_public_dns" {
  description = "The bastion must exist in order to provide complete instructions to establish connection with this host, and also aquire the security group enabling ssh between both hosts."
  type        = string
}
