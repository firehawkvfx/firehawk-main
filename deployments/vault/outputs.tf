output "security_group_id_consul_cluster" {
  value = module.vault.security_group_id_consul_cluster
}

output "instructions" {
  value = "To initialise the vault, login to a server and run: vault operator init -recovery-shares=1 -recovery-threshold=1"
}