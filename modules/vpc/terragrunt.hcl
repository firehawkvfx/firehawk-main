include {
  path = find_in_parent_folders()
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
}

dependency "vpc-data" {
  config_path = "../vpc-data"
  mock_outputs = {
    vpc_cidr = ""
  }
}

inputs = merge(
  local.common_vars.inputs,
  {
    enable_nat_gateway = true
    vpc_cidr           = dependency.vpc-data.outputs.vpc_cidr
    public_subnets     = dependency.vpc-data.outputs.public_subnets
    private_subnets    = dependency.vpc-data.outputs.private_subnets
  }
)

dependencies {
  paths = [ # not strictly dependencies, but if they fail, there is no point in continuing to deploy a vpc or anything else.
    "../vpc-data"
  ]
}
