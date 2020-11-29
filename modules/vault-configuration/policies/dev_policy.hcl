path "dev/*"
{
  capabilities = ["list", "read", "update"]
}

path "dev/data/user"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}