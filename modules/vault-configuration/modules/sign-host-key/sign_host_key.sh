#!/bin/bash

set -e

# Aquire the public CA cert to approve an authority
vault read -field=public_key ssh-client-signer/config/ca | sudo tee /etc/ssh/trusted-user-ca-keys.pem

# If TrustedUserCAKeys not defined, then add it to sshd_config
sudo grep -q "^TrustedUserCAKeys" /etc/ssh/sshd_config || echo 'TrustedUserCAKeys' | sudo tee --append /etc/ssh/sshd_config
# Ensure the value for TrustedUserCAKeys is configured correctly
sudo sed -i 's/TrustedUserCAKeys.*/TrustedUserCAKeys /etc/ssh/trusted-user-ca-keys.pem' /etc/ssh/sshd_config

# Sign this host's public key
vault write -format=json ssh-host-signer/sign/hostrole \
    cert_type=host \
    public_key=@/etc/ssh/ssh_host_rsa_key.pub 

# Aquire the cert
vault write -field=signed_key ssh-host-signer/sign/hostrole \
    cert_type=host \
    public_key=@/etc/ssh/ssh_host_rsa_key.pub > /etc/ssh/ssh_host_rsa_key-cert.pub

sudo chmod 0640 /etc/ssh/ssh_host_rsa_key-cert.pub

# Private key and cert are both required for ssh to another host.
sudo grep -q "^HostKey" /etc/ssh/sshd_config || echo 'HostKey' | sudo tee --append /etc/ssh/sshd_config
sudo sed -i 's/HostKey.*/HostKey /etc/ssh/ssh_host_rsa_key' /etc/ssh/sshd_config

sudo grep -q "^HostCertificate" /etc/ssh/sshd_config || echo 'HostCertificate' | sudo tee --append /etc/ssh/sshd_config
sudo sed -i 's/HostCertificate.*/HostCertificate /etc/ssh/ssh_host_rsa_key-cert.pub' /etc/ssh/sshd_config

# Add the CA cert to use it for known hosts
# curl http://vault.service.consul:8200/v1/ssh-host-signer/public_key
key=$(vault read -field=public_key ssh-host-signer/config/ca)

sudo grep -q "^@cert-authority \*\.consul" $HOME/.ssh/known_hosts || echo '@cert-authority *.consul' | sudo tee --append $HOME/.ssh/known_hosts
sudo sed -i "s/@cert-authority \*\.consul.*/@cert-authority *.consul ssh-rsa $key" $HOME/.ssh/known_hosts
