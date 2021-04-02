# You must be logged into Vault for this module to function. 

provider "vault" {
}

# provider "aws" {
#   #  if you haven't installed and configured the aws cli, you will need to provide your aws access key and secret key.
#   # in a dev environment these version locks below can be disabled.  in production, they should be locked based on the suggested versions from terraform init.
#   version = "~> 3.15.0"
# }

### Auth methods ###
resource "vault_auth_backend" "example" {
  type = "userpass"
}

# Produce certificates for mongo

resource "vault_mount" "pki" {
  path                      = "pki"
  type                      = "pki"
  description               = "PKI for the ROOT CA"
  default_lease_ttl_seconds = 315360000 # 10 years
  max_lease_ttl_seconds     = 315360000 # 10 years
}

resource "vault_pki_secret_backend_crl_config" "pki_crl_config" {
  backend = vault_mount.pki.path
  expiry  = "72h"
  disable = false
}

resource "vault_pki_secret_backend_root_cert" "root" {
  depends_on = [vault_mount.pki]

  backend = vault_mount.pki.path

  type               = "internal"
  common_name        = "Root CA"
  ttl                = "315360000"
  format             = "pem"
  private_key_format = "der"
  key_type           = "rsa"
  key_bits           = 4096
  # exclude_cn_from_sans = true
  # ou = "My OU"
  # organization = "Firehawk VFX"
}

resource "vault_mount" "pki_int" {
  path                      = "pki_int"
  type                      = "pki"
  description               = "PKI for the ROOT CA"
  default_lease_ttl_seconds = 315360000 # 10 years
  max_lease_ttl_seconds     = 315360000 # 10 years
}

resource "vault_pki_secret_backend_crl_config" "pki_int_crl_config" {
  backend = vault_mount.pki_int.path
  expiry  = "72h"
  disable = false
}

resource "vault_pki_secret_backend_intermediate_cert_request" "intermediate" {
  depends_on = [vault_mount.pki, vault_mount.pki_int]

  backend = vault_mount.pki_int.path

  type               = "internal"
  common_name        = "pki-ca-int"
  format             = "pem"
  private_key_format = "der"
  key_type           = "rsa"
  key_bits           = "4096"
}

resource "vault_pki_secret_backend_root_sign_intermediate" "root" {
  depends_on = [vault_pki_secret_backend_intermediate_cert_request.intermediate]

  backend = vault_mount.pki.path

  csr                  = vault_pki_secret_backend_intermediate_cert_request.intermediate.csr
  common_name          = "pki-ca-int"
  exclude_cn_from_sans = true
  # ou = "Developement"
  organization = "firehawkvfx.com"
  ttl          = 252288000 # 8 years
}

resource "vault_pki_secret_backend_intermediate_set_signed" "intermediate" {
  backend = vault_mount.pki_int.path

  # TODO: check this is correct against https://medium.com/@stvdilln/creating-a-certificate-authority-with-hashicorp-vault-and-terraform-4d9ddad31118
  certificate = "${vault_pki_secret_backend_root_sign_intermediate.root.certificate}\n${vault_pki_secret_backend_root_cert.root.certificate}"
}

resource "vault_pki_secret_backend_role" "firehawkvfx-dot-com" {
  backend        = vault_mount.pki_int.path
  name           = "firehawkvfx-dot-com"
  generate_lease = true
  allow_any_name = true
  ttl            = 157680000 # 5 years
  max_ttl        = 157680000 # 5 years
}

# after deployment you can create a token for the pki_int role:
# vault token create -policy=pki_int -ttl=24h
# then login with it:
# vault login <my token>
# Then you can generate a cert with:
# vault write pki_int/issue/firehawkvfx-dot-com common_name=deadlinedb.service.consul
# or you can generate and write output to files like so:
# vault write -format=json pki_int/issue/firehawkvfx-dot-com common_name=deadlinedb.service.consul ttl=8760h | tee \
# >(jq -r .data.certificate > ca.pem) \
# >(jq -r .data.issuing_ca > issuing_ca.pem) \
# >(jq -r .data.private_key > ca-key.pem)

### SSH key signing for machines that wish to ssh to other known hosts ###

resource "vault_mount" "ssh_signer" {
  path        = "ssh-client-signer"
  type        = "ssh"
  description = "The SSH key signer certifying machines to authenticate ssh sessions"
}

resource "vault_ssh_secret_backend_ca" "ssh_signer_ca" {
  backend              = vault_mount.ssh_signer.path
  generate_signing_key = true
}

resource "vault_ssh_secret_backend_role" "ssh_role" {
  name                    = "ssh-role"
  backend                 = vault_mount.ssh_signer.path
  allow_user_certificates = true
  allowed_users           = "*"
  allowed_extensions      = "permit-pty,permit-port-forwarding"
  default_extensions = tomap({
    "permit-pty"              = "",
    "permit-agent-forwarding" = "",
    "permit-port-forwarding"  = "",
    "valid_principals" : "centos,ubuntu"
  })
  key_type         = "ca"
  default_user     = "centos"
  algorithm_signer = "rsa-sha2-256"
  # valid_principals= "ubuntu,centos"
  # ttl = "30m0s"
  ttl = "720h"
  # cidr_list     = "0.0.0.0/0"
}

### SSH key signing for machines to be recognised as known hosts ### # note need to use rsa-sha2-256 now https://ibug.io/blog/2020/04/ssh-8.2-rsa-ca/

resource "vault_mount" "ssh_host_signer" {
  path        = "ssh-host-signer"
  type        = "ssh"
  description = "The SSH host key signer enabling machines to be recognised certified known hosts"
}

resource "vault_ssh_secret_backend_ca" "ssh_host_signer_ca" {
  backend              = vault_mount.ssh_host_signer.path
  generate_signing_key = true
}

resource "vault_ssh_secret_backend_role" "host_role" {
  name                    = "hostrole"
  backend                 = vault_mount.ssh_host_signer.path
  key_type                = "ca"
  ttl                     = "87600h"
  max_ttl                 = "87600h"
  allow_host_certificates = true
  allowed_domains         = "localdomain,consul,${var.aws_external_domain}"
  algorithm_signer        = "rsa-sha2-256"
  allow_subdomains        = true
}