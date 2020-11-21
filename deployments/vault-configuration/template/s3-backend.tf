### Block to configure remote state
terraform {
  backend "s3" {
    # Replace this with your bucket name!
    bucket         = "state.terraform.$TF_VAR_bucket_extension"
    key            = "main/vault-configuration/terraform.tfstate"
    region = "$AWS_DEFAULT_REGION"
    # Replace this with your DynamoDB table name!
    dynamodb_table = "locks.state.terraform.$TF_VAR_bucket_extension"
    encrypt        = true
  }
}
### End block for remote state