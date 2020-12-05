output "s3_bucket_software_bucket_domain_name" {
  value = aws_s3_bucket.shared_bucket.bucket_domain_name
}

output "multiple_account_iam_role" {}
  value = aws_iam_role.multiple_account_assume_role.arn
}