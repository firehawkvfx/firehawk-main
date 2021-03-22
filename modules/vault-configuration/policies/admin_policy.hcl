# Manage auth methods broadly across Vault
path "auth/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# these may be required https://registry.terraform.io/providers/hashicorp/vault/latest/docs#using-vault-credentials-in-terraform-configuration
# terraform must create other tokens

path "auth/token/*" {
  capabilities = ["create", "update", "read", "delete", "list"]
}

path "auth/token/create" {
  capabilities = ["create", "update"]
}

path "auth/token/renew" {
  capabilities = ["update"]
}

path "auth/token/renew-self" {
  capabilities = ["update"]
}

# These are provided to ensure vpn_read_config_policy is a subset of admin 
path "auth/token/lookup-accessor" {
  capabilities = ["update"]
}

path "auth/token/revoke-accessor" {
  capabilities = ["update"]
}

# Create, update, and delete auth methods
path "sys/auth/*"
{
  capabilities = ["create", "update", "delete", "sudo"]
}

# List auth methods
path "sys/auth"
{
  capabilities = ["read"]
}

# List existing policies
path "sys/policies/acl"
{
  capabilities = ["list"]
}

# Create and manage ACL policies
path "sys/policies/acl/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# List, create, update, and delete key/value secrets
path "secret/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Manage secrets engines
path "sys/mounts/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# List existing secrets engines.
path "sys/mounts"
{
  capabilities = ["read"]
}

# Read health checks
path "sys/health"
{
  capabilities = ["read", "sudo"]
}

# Permisison to various environments
path "dev/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "green/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "blue/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "main/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

# add capabilities so that vpn read policy is subset of admin
# provide ability to read stored vpn file paths

path "dev/data/files/usr/local/openvpn_as/scripts/seperate/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "green/data/files/usr/local/openvpn_as/scripts/seperate/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "blue/data/files/usr/local/openvpn_as/scripts/seperate/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "main/data/files/usr/local/openvpn_as/scripts/seperate/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Allow Permision to create / sign SSL certificates

path "pki_int/issue/*" {
    capabilities = ["create", "update"]
}

path "pki_int/roles/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "pki_int/config/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "pki_int/certs" {
  capabilities = ["list"]
}

path "pki_int/revoke" {
  capabilities = ["create", "update"]
}

path "pki_int/tidy" {
  capabilities = ["create", "update"]
}

path "pki/config/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "pki/cert/ca" {
  capabilities = ["read"]
}

# SSH host certificates

path "ssh-host-signer/roles/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "ssh-host-signer/config/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "ssh-host-signer/sign/*" {
    capabilities = ["create", "read", "update", "delete", "list"]
}

# SSH client certificates

path "ssh-client-signer/roles/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "ssh-client-signer/config/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "ssh-client-signer/sign/*" {
    capabilities = ["create", "read", "update", "delete", "list"]
}