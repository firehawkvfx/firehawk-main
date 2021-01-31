# Manage auth methods broadly across Vault
path "auth/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
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

path "auth/token/renew" {
  capabilities = ["update"]
}

path "auth/token/renew-self" {
  capabilities = ["update"]
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

path "ssh-client-signer/roles" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "ssh-client-signer/config/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "ssh-client-signer/sign/*" {
    capabilities = ["create", "read", "update", "delete", "list"]
}