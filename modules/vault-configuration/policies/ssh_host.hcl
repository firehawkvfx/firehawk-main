# Provides the ability to request signed SSH host certificates.

path "ssh-host-signer/sign/hostrole" {
    capabilities = ["create", "update"]
}

path "ssh-host-signer/config/ca" {
    capabilities = ["read"]
}