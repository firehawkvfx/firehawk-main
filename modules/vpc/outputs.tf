output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

output "consul_client_security_group" {
  value = module.consul_client_security_group.consul_client_sg_id
}