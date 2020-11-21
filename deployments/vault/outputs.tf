output "security_group_id_consul_cluster" {
  value = module.vault.security_group_id_consul_cluster
}

output "instructions" {
  value = "To initialise the vault, login to a server and run: vault operator init -recovery-shares=1 -recovery-threshold=1\n To connnect this node to the consul cluster, run: /opt/consul/bin/run-consul --client --cluster-tag-key \"${consul_cluster_tag_key}\" --cluster-tag-value \"${consul_cluster_tag_value}\""
}