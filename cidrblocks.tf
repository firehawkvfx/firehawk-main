

module "dev_cidrs" {
  source = "hashicorp/subnets/cidr"

  base_cidr_block = "10.1.0.0/16"
  networks = [
    {
      name     = "vault_vpc"
      new_bits = 8
    },
    {
      name     = "render_vpc"
      new_bits = 1
    }
  ]
}