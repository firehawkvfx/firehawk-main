include {
  path = find_in_parent_folders()
}

dependencies {
  paths = [
    "../terraform-aws-iam-profile-bastion", 
    "../terraform-aws-iam-profile-deadline-db", 
    "../terraform-aws-iam-profile-openvpn",
    "../terraform-aws-iam-profile-provisioner",  
    "../terraform-aws-iam-profile-vault-client",
    ]
}

skip = true