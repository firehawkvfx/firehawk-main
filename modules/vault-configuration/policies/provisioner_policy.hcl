# The provisioner policy is for packer instances and other automation that requires read access to vault

path "dev/*"
{
  capabilities = ["list", "read"]
}

path "dev/data/user"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}