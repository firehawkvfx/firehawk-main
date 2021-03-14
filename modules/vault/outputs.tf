output "security_group_id_consul_cluster" {
  value = module.vault.security_group_id_consul_cluster
}

output "Instructions" {
  value = <<EOF
  To initialise the vault on first start ssh to a vault server and run:
  export VAULT_ADDR=https://vault.service.consul:8200
  vault operator init -recovery-shares=1 -recovery-threshold=1
  Store the initial root token provided in a password manager (encrypted).

  To connect this current instance to the vault for the first time, and updating the certificate, install vault without sudo:
  ./install-consul-vault-client --vault-module-version v0.13.11  --vault-version 1.5.5 --consul-module-version v0.8.0 --consul-version 1.8.4 --build amazonlinux2 --cert-file-path /home/ec2-user/.ssh/tls/ca.crt.pem
  
  To connnect this instance you are using currently to the consul cluster on subsequent runs, and find the vault by DNS name:
  sudo /opt/consul/bin/run-consul --client --cluster-tag-key "$${consul_cluster_tag_key}" --cluster-tag-value "$${consul_cluster_tag_value}"

  You should be able to login from thsi instance with:
  vault login
EOF
}