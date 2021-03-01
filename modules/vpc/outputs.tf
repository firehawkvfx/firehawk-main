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