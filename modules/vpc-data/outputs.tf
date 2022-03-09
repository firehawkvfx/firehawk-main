output "vpc_cidr" {
  value = module.vaultvpc_all_subnet_cidrs.base_cidr_block
}

output "public_subnets" {
  value = module.vaultvpc_all_public_subnet_cidrs.networks[*].cidr_block
}

output "private_subnets" {
  value = module.vaultvpc_all_private_subnet_cidrs.networks[*].cidr_block
}