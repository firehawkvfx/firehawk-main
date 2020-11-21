### Block to configure remote state
terraform {
  backend "s3" {
    # Replace this with your bucket name!
    bucket         = "state.terraform.$TF_VAR_bucket_extension"
    key            = "main/vault-configuration/terraform.tfstate"
    region = data.aws_region.current.name
    # Replace this with your DynamoDB table name!
    dynamodb_table = "locks.state.terraform.$TF_VAR_bucket_extension"
    encrypt        = true
  }
}
output "s3_bucket_arn" {
  value       = aws_s3_bucket.terraform_state.arn
  description = "The ARN of the S3 bucket for terraform state"
}
output "dynamodb_table_name" {
  value       = aws_dynamodb_table.terraform_locks.name
  description = "The name of the DynamoDB table to lock terraform state."
}
### End block for remote state