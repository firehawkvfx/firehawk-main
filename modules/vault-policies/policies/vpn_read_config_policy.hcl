# when using the vault_token terraform resource we need to be able to renew and revoke tokens

path "auth/token/lookup-accessor" {
  capabilities = ["update"]
}

path "auth/token/revoke-accessor" {
  capabilities = ["update"]
}

# path "dev/data/user"
# {
#   capabilities = ["create", "read", "update", "delete", "list"]
# }

# provide ability to read stored vpn file paths

path "dev/data/files/usr/local/openvpn_as/scripts/seperate/*" # to be deprecated
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "dev/data/network/vpn_files/usr/local/openvpn_as/scripts/seperate/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "green/data/files/usr/local/openvpn_as/scripts/seperate/*" # to be deprecated
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "green/data/network/vpn_files/usr/local/openvpn_as/scripts/seperate/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "blue/data/files/usr/local/openvpn_as/scripts/seperate/*" # to be deprecated
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "blue/data/network/vpn_files/usr/local/openvpn_as/scripts/seperate/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "main/data/files/usr/local/openvpn_as/scripts/seperate/*" # to be deprecated
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "main/data/network/vpn_files/usr/local/openvpn_as/scripts/seperate/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}