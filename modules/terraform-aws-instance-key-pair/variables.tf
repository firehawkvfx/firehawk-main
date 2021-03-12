variable "vault_public_key" {
  description = "The public key of the host used to ssh into the vault cluster"
  type = string
  default = ""
}
variable "common_tags" {
  description = "Common tags for all resources in a deployment run."
  type        = map(string)
}