# Provides the ability to request signed SSH host certificates.

path "ssh-host-signer/sign/hostrole" {
    capabilities = ["create", "update"]
}

# This CA defines signed hosts, for known hosts. 
path "ssh-host-signer/config/ca" {
    capabilities = ["read"]
}

# This CA defines what hosts can sign in as clients
path "ssh-client-signer/config/ca" {
    capabilities = ["read"]
}