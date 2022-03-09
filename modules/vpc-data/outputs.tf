output "vpc_cidr" {
  value = module.vaultvpc_all_subnet_cidrs.base_cidr_block
}

resource "aws_ssm_parameter" "vaultvpc_vpc_cidr" {
  name  = "tmp_vaultvpc_vpc_cidr"
  type  = "String"
  value = module.vaultvpc_all_subnet_cidrs.base_cidr_block
}

output "public_subnets" {
  value = module.vaultvpc_all_public_subnet_cidrs.networks[*].cidr_block
}

resource "aws_ssm_parameter" "vaultvpc_vpc_cidr" {
  name  = "tmp_vaultvpc_public_subnets"
  type  = "String"
  value = module.vaultvpc_all_public_subnet_cidrs.networks[*].cidr_block
}

output "private_subnets" {
  value = module.vaultvpc_all_private_subnet_cidrs.networks[*].cidr_block
}

resource "aws_ssm_parameter" "vaultvpc_private_subnets" {
  name  = "tmp_vaultvpc_private_subnets"
  type  = "String"
  value = module.vaultvpc_all_private_subnet_cidrs.networks[*].cidr_block
}