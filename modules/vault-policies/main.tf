provider "vault" {
}
resource "vault_policy" "admin_policy" {
  name   = "admins"
  policy = file("policies/admin_policy.hcl")
}
resource "vault_policy" "dev_policy" {
  name   = "dev"
  policy = file("policies/dev_policy.hcl")
}
resource "vault_policy" "green_policy" {
  name   = "green"
  policy = file("policies/green_policy.hcl")
}
resource "vault_policy" "blue_policy" {
  name   = "blue"
  policy = file("policies/blue_policy.hcl")
}
resource "vault_policy" "main_policy" {
  name   = "main"
  policy = file("policies/main_policy.hcl")
}
resource "vault_policy" "deadline_db_policy" {
  name   = "deadline_db"
  policy = file("policies/deadline_db_policy.hcl")
}
resource "vault_policy" "deadline_client_policy" {
  name   = "deadline_db"
  policy = file("policies/deadline_client_policy.hcl")
}
resource "vault_policy" "provisioner_policy" {
  name   = "provisioner"
  policy = file("policies/provisioner_policy.hcl")
}
resource "vault_policy" "vpn_server_policy" {
  name   = "vpn_server"
  policy = file("policies/vpn_server_policy.hcl")
}
resource "vault_policy" "vpn_read_config_policy" {
  name   = "vpn_read_config"
  policy = file("policies/vpn_read_config_policy.hcl")
}
resource "vault_policy" "pki_int_policy" {
  name   = "pki_int"
  policy = file("policies/pki_int.hcl")
}
resource "vault_policy" "ssh_host_policy" {
  name   = "ssh_host"
  policy = file("policies/ssh_host.hcl")
}