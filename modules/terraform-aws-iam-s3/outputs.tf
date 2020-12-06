output "provisioner_instance_profile_arn" {
  value = aws_iam_instance_profile.provisioner_instance_profile.arn
}
output "provisioner_instance_profile_name" {
  value = aws_iam_instance_profile.provisioner_instance_profile.name
}
output "provisioner_instance_role_name" {
  value = aws_iam_role.provisioner_instance_role.name
}
