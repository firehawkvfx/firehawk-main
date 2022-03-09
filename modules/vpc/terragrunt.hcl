include {
  path = find_in_parent_folders()
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
}

dependency "data" {
  config_path = "../vpc-data"
  mock_outputs = {
    vpc_cidr        = ""
    public_subnets  = []
    private_subnets = []
  }
}

dependencies {
  paths = [
    "../vpc-data"
  ]
}

inputs = merge(
  local.common_vars.inputs,
  {
    enable_nat_gateway = true
    vpc_cidr           = dependency.data.outputs.vpc_cidr
    public_subnets     = dependency.data.outputs.public_subnets
    private_subnets    = dependency.data.outputs.private_subnets
  }
)


