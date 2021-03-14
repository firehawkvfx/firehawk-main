output "security_group_id_consul_cluster" {
  value = module.vault.security_group_id_consul_cluster
}

output "Instructions" {
  value = <<EOF
  To initialise the vault on first start ssh to a vault server and init:
  ssh ubuntu@(Vault Private IP)
  export VAULT_ADDR=https://vault.service.consul:8200
  or
  export VAULT_ADDR=https://127.0.0.1:8200
  vault operator init -recovery-shares=1 -recovery-threshold=1
  vault login (Root token provided above)
  vault status

  Store the initial root token provided in a password manager (encrypted).  Next you will configure vault policies...

  To connect this current instance to the vault for the first time, and updating the certificate, install vault without sudo:
  ./install-consul-vault-client --vault-module-version v0.13.11  --vault-version 1.5.5 --consul-module-version v0.8.0 --consul-version 1.8.4 --build amazonlinux2 --cert-file-path /home/ec2-user/.ssh/tls/ca.crt.pem
  
  To connnect this instance you are using currently to the consul cluster on subsequent runs, and find the vault by DNS name:
  sudo /opt/consul/bin/run-consul --client --cluster-tag-key "$${consul_cluster_tag_key}" --cluster-tag-value "$${consul_cluster_tag_value}"

  You should be able to login from this instance with:
  vault login

  continue to modules/vault-configuration to intialise values for first time use:
  ./generate-plan-init
  terraform apply "tfplan"

  The apply the rest of the policies,  this step can be performed at any time you wish to update policies provided you are logged in as an admin.
  ./generate-plan
  terraform apply "tfplan"
EOF
}