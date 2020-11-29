output "security_group_id_consul_cluster" {
  value = module.vault.security_group_id_consul_cluster
}

output "instructions" {
  value = <<EOF
  To initialise the vault on first start:
  login to a server and run: vault operator init -recovery-shares=1 -recovery-threshold=1
  To connect this instance to the vault for the first time, and updating the certificate:
  ./install-consul-vault-client --vault-module-version v0.13.11  --vault-version 1.5.5 --consul-module-version v0.8.0 --consul-version 1.8.4 --build amazonlinux2 --cert-file-path /home/ec2-user/.ssh/tls/ca.crt.pem
  To connnect this node to the consul cluster on subsequent runs, and find the vault by DNS name:
  /opt/consul/bin/run-consul --client --cluster-tag-key "$${consul_cluster_tag_key}" --cluster-tag-value "$${consul_cluster_tag_value}"
EOF
}