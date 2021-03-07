variable "name" {
    description = "The name for the policy"
    type = string
    default = "STSGetCallerIdentityPolicy"
}

variable "role" {
    description = "The aws_iam_role role id to attach the policy to"
    type = string
}