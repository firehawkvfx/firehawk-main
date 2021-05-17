output "security_group_id_consul_cluster" {
  value = module.vault.security_group_id_consul_cluster
}

# output "Instructions" {
#   value = <<EOF
#   To initialise the vault on first start ssh to a vault server and init:
#   ssh ubuntu@(Vault Private IP)
#   consul catalog services # should list both consul and vault
#   vault status # should say initilised false
#   vault operator init -recovery-shares=1 -recovery-threshold=1
#   vault login (Root token provided above)
#   vault status

#   Store the initial root token provided in a password manager (encrypted).  Next you will configure vault policies...

#   To connect this current instance to the vault for the first time, and updating the certificate, install vault without sudo:
#   ./install-consul-vault-client --vault-module-version v0.15.1  --vault-version 1.6.1 --consul-module-version v0.8.0 --consul-version 1.9.2 --build amazonlinux2 --cert-file-path /home/ec2-user/.ssh/tls/ca.crt.pem
  
#   To connnect this instance you are using currently to the consul cluster on subsequent runs, and find the vault by DNS name:
#   sudo /opt/consul/bin/run-consul --client --cluster-tag-key "$${consul_cluster_tag_key}" --cluster-tag-value "$${consul_cluster_tag_value}"

#   You should be able to login from this instance with:
#   vault login

#   continue to `cd modules/vault-configuration` to intialise values for first time use:
#   ./generate-plan-init
#   terraform apply "tfplan"

#   Create a new token under th admins policy, and do not use the root token from now on.  We also include other policies you may need to create tokens for:
#   vault token create -policy=admins -policy=vpn_read_config -explicit-max-ttl=720h

#   The apply the rest of the policies,  this step can be performed at any time you wish to update policies provided you are logged in as an admin.
#   ./generate-plan
#   terraform apply "tfplan"

#   You can now sign the cloud 9 host for SSH in modules by running
#   ./modules/known-hosts/known_hosts.sh
#   ./modules/sign-host-key/sign_host_key.sh
#   ./modules/sign-ssh-key/sign_ssh_key.sh

#   # after this one time initialisation you can use the "wake" script to continue. 
# EOF
# }