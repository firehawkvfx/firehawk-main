variable "resourcetier" {
  description = "The resource tier uniquely defining the deployment area.  eg: dev/green/blue/main"
  type        = string
}
variable "vault_vpc_subnet_count" { # If adjusting the max here, consider 2^new_bits = vault_vpc_subnet_count when constructing the subnets.
  description = "(1-4) The number of private and public subnets to use. eg: 1 will result in one public and 1 private subnet in 1AZ.  3 will result in 3 private and public subnets spread across 3 AZ's. Currently the vault cluster only uses 1 subnet."
  default     = 1
  validation {
    condition = (
      var.vault_vpc_subnet_count <= 4 &&
      var.vault_vpc_subnet_count > 0
    )
    error_message = "The var vault_vpc_subnet_count must be between 1-4 (inclusive)."
  }
}