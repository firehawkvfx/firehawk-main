# variable "envtier" {
#   description = "The environment tier eg: dev, prod"
#   type = string
#   default = "dev"
# }

variable "resourcetier" {
  description = "The resource tier eg: green, blue, grey"
  type = string
}

variable "secret_name" {
  description = "The name of the data in the path"
  type        = string
}

variable "system_default" {
  description = "The map defining the system defaults for the secret"
  type        = map(string)
}

variable "mount_path" {
  description = "The mount path in vault"
  type        = string
}

variable "restore_defaults" {
  description = "If true, will reset all values to system defaults"
  type        = bool
  default     = false
}

# variable "init" {
#   description = "If true, will only ensure paths exist."
#   type        = bool
#   default     = false
# }