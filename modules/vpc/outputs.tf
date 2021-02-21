output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

output "bastion_public_ip" {
  value = module.vpc.bastion_public_ip
}

output "bastion_graphical_public_ip" {
  value = module.vpc.bastion_graphical_public_ip
}

output "consul_client_security_group" {
  value = module.vpc.consul_client_security_group
}

output "Instructions" {
  value = <<EOF
  To use connect to the graphical bastion, you must first set a user password using ssh:
  ssh ec2-user@${module.vpc.bastion_graphical_public_ip}
  sudo passwd ec2-user

  Then using the NICE DCV Client installed on your desktop, you can connect to ${module.vpc.bastion_graphical_public_ip} with your password.

  Ensure you correctly set the remote_ip_graphical_cidr variable (ending in /32).  This is the remote public IP address of your host running the NICE DCV client.
  This variable is used to define the security groups.
  
  You can change this variable and use 'terraform apply' to update the security group if you forgot to do this or if your IP changes because it is not static. 
EOF
}