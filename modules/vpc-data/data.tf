# Terraform will automatically configure multiple VPCs and subnets within this CIDR range for any resourcetier ( dev / green / blue / main ).
data "aws_ssm_parameter" "combined_vpcs_cidr" {
  name = "/firehawk/resourcetier/${var.resourcetier}/combined_vpcs_cidr"
}

module "resourcetier_all_vpc_cidrs" { # all vpcs contained in the combined_vpcs_cidr (current resource tier dev or green or blue or main)
  source = "hashicorp/subnets/cidr"

  base_cidr_block = data.aws_ssm_parameter.combined_vpcs_cidr.value
  networks = [
    {
      name     = "deployervpc"
      new_bits = 9
    },
    {
      name     = "vaultvpc"
      new_bits = 9
    },
    {
      name     = "rendervpc"
      new_bits = 1
    }
  ]
}

module "vaultvpc_all_subnet_cidrs" { # all private/public subnet ranges 
  source = "hashicorp/subnets/cidr"

  base_cidr_block = module.resourcetier_all_vpc_cidrs.network_cidr_blocks["vaultvpc"]
  networks = [
    {
      name     = "privatesubnets"
      new_bits = 1
    },
    {
      name     = "publicsubnets"
      new_bits = 1
    }
  ]
}

module "vaultvpc_all_private_subnet_cidrs" {
  source = "hashicorp/subnets/cidr"

  base_cidr_block = module.vaultvpc_all_subnet_cidrs.network_cidr_blocks["privatesubnets"]
  networks = [
    for i in range(var.vault_vpc_subnet_count) : { name = format("privatesubnet%s", i), new_bits = 2 }
  ]
}

module "vaultvpc_all_public_subnet_cidrs" {
  source = "hashicorp/subnets/cidr"

  base_cidr_block = module.vaultvpc_all_subnet_cidrs.network_cidr_blocks["publicsubnets"]
  networks = [
    for i in range(var.vault_vpc_subnet_count) : { name = format("publicsubnet%s", i), new_bits = 2 }
  ]
}
