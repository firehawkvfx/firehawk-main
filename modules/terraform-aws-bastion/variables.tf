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