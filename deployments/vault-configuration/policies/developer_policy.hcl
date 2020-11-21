path "developers/*"
{
  capabilities = ["list", "read", "update"]
}

path "developers/data/user"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}