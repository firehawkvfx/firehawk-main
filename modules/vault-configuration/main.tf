# You must be logged into Vault for this module to function. 

provider "vault" {
}

provider "aws" {
  #  if you haven't installed and configured the aws cli, you will need to provide your aws access key and secret key.
  # in a dev environment these version locks below can be disabled.  in production, they should be locked based on the suggested versions from terraform init.
  version = "~> 3.15.0"
}



resource "vault_mount" "dev" {
  path        = "dev"
  type        = "kv-v2"
  description = "KV2 Secrets Engine for dev."
}

resource "vault_mount" "green" {
  path        = "green"
  type        = "kv-v2"
  description = "KV2 Secrets Engine for green."
}

resource "vault_mount" "blue" {
  path        = "blue"
  type        = "kv-v2"
  description = "KV2 Secrets Engine for blue."
}

resource "vault_mount" "main" {
  path        = "main"
  type        = "kv-v2"
  description = "KV2 Secrets Engine for main."
}

module "update-values-dev" { # Init defaults
  source           = "./modules/update-values"
  init             = var.init
  resourcetier     = "dev" # dev, green, blue, or main
  mount_path       = "dev"
  for_each         = local.dev
  secret_name      = each.key
  system_default   = each.value
  restore_defaults = var.restore_defaults # defaults will always be updated if the present value matches a present default, but if this var is true, any present user values will be reset always.
}

module "update-values-green" { # Init defaults
  source           = "./modules/update-values"
  init             = var.init
  resourcetier     = "green" # dev, green, blue, or main
  mount_path       = "green"
  for_each         = local.green
  secret_name      = each.key
  system_default   = each.value
  restore_defaults = var.restore_defaults # defaults will always be updated if the present value matches a present default, but if this var is true, any present user values will be reset always.
}

module "update-values-blue" { # Init defaults
  source           = "./modules/update-values"
  init             = var.init
  resourcetier     = "blue" # dev, green, blue, or main
  mount_path       = "blue"
  for_each         = local.blue
  secret_name      = each.key
  system_default   = each.value
  restore_defaults = var.restore_defaults # defaults will always be updated if the present value matches a present default, but if this var is true, any present user values will be reset always.
}

module "update-values-main" { # Init defaults
  source           = "./modules/update-values"
  init             = var.init
  resourcetier     = "main" # dev, green, blue, or main
  mount_path       = "main"
  for_each         = local.main
  secret_name      = each.key
  system_default   = each.value
  restore_defaults = var.restore_defaults # defaults will always be updated if the present value matches a present default, but if this var is true, any present user values will be reset always.
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_canonical_user_id" "current" {}



### Auth methods ###
resource "vault_auth_backend" "example" {
  type = "userpass"
}

# resource "vault_token_auth_backend_role" "vpn_vault_token_role" {
#   role_name              = "vpn-server-vault-token-creds-role"
#   allowed_policies       = ["vpn_server", "ssh_host"]
#   token_period           = 1200
#   renewable              = true
#   token_explicit_max_ttl = 86400
#   # disallowed_policies = ["default"]
#   # token_bound_cidrs = ["10.0.0.0/16"]
#   # token_num_uses   = 1
#   # orphan           = true
#   # path_suffix         = "path-suffix"
# }

# resource "vault_aws_secret_backend" "aws" {
#   # Enable dynamic generation of aws IAM user id's and secret keys
#   path = "aws"
#   region = data.aws_region.current.name
#   default_lease_ttl_seconds = 600
#   # max_lease_ttl_seconds = 60*60*24 # 1 day. Note vault must be running to revoke the credentials
# }

# module "vault_client_provisioner_iam" { # the arn of a role will turn into an id when it is created, which may change, so we probably only want to do this once, or the refs in vault will be incorrect.
#   source = "../../modules/aws-iam-role-vault-client"
#   role_name = "VaultUserRole"
# }
# resource "vault_aws_secret_backend_role" "vault_vpn_role" {
#   backend = vault_aws_secret_backend.aws.path
#   name    = "vpn-server-vault-iam-creds-role"
#   credential_type = "iam_user"
#   # role_arns             = [ module.vault_client_provisioner_iam.vault_client_role_arn ]

#   policy_document = <<EOT
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Action": "iam:*",
#       "Resource": "*"
#     }
#   ]
# }
# EOT
# }

# resource "vault_aws_auth_backend_role" "vpn_server_aws_secret_based" {
#   # using generated aws key based creds, allows acces to vault.  see https://discuss.hashicorp.com/t/generating-dynamic-access-keys-across-multiple-aws-accounts/5931
#   backend                         = vault_auth_backend.aws.path
#   token_ttl                       = 600
#   token_max_ttl                   = 600
#   token_policies                  = ["vpn_server"]
#   role                            = "vpn-server-vault-iam-creds-role"
#   auth_type                       = "iam"
#   bound_account_ids               = [ data.aws_caller_identity.current.account_id ]
#   bound_iam_role_arns             = [ module.vault_client_provisioner_iam.vault_client_role_arn ]
#   # bound_iam_principal_arn = "arn:aws:iam::123456789012:role/*"
# }

# data "vault_aws_access_credentials" "creds" {
#   backend = "aws"
#   role    = "vpn-server-vault-iam-creds-role"
# }

# Once vault is configured below with the provisioner-vault-role, it is possible for any instance with the correct IAM profile to authenticate.
# export VAULT_ADDR=https://vault.service.consul:8200
# vault login -method=aws header_value=vault.service.consul role=provisioner-vault-role

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

# resource "vault_token_auth_backend_role" "host_vault_token_role" {
#   role_name        = "host-vault-token-creds-role"
#   allowed_policies = ["ssh_host"]
#   # disallowed_policies = ["default"]
#   # token_bound_cidrs = ["10.0.0.0/16"]
#   # token_num_uses   = 1
#   token_period           = 6000 # 100 mins TODO reduce this after testing
#   renewable              = true
#   token_explicit_max_ttl = 86400
#   # orphan           = true
#   # path_suffix         = "path-suffix"
# }