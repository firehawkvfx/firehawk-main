#!/bin/bash

set -e

# Aquire the public CA cert to approve an authority
trusted_ca="/etc/ssh/trusted-user-ca-keys.pem"
vault read -field=public_key ssh-client-signer/config/ca | sudo tee $trusted_ca

# If TrustedUserCAKeys not defined, then add it to sshd_config
sudo grep -q "^TrustedUserCAKeys" /etc/ssh/sshd_config || echo 'TrustedUserCAKeys' | sudo tee --append /etc/ssh/sshd_config
# Ensure the value for TrustedUserCAKeys is configured correctly
sudo sed -i "s@TrustedUserCAKeys.*@TrustedUserCAKeys $trusted_ca@g" /etc/ssh/sshd_config 

# Sign the users public key
vault write ssh-client-signer/sign/ssh-role \
    public_key=@$HOME/.ssh/id_rsa.pub

## This can bue customized:
#  vault write ssh-client-signer/sign/ssh-role -<<"EOH"
# {
#   "public_key": "ssh-rsa AAA...",
#   "valid_principals": "my-user",
#   "key_id": "custom-prefix",
#   "extensions": {
#     "permit-pty": "",
#     "permit-port-forwarding": ""
#   }
# }
# EOH

# Save the signed public cert
vault write -field=signed_key ssh-client-signer/sign/ssh-role \
    public_key=@$HOME/.ssh/id_rsa.pub > $HOME/.ssh/id_rsa-cert.pub

sudo chmod 0644 $HOME/.ssh/id_rsa-cert.pub

# View result metadata
ssh-keygen -Lf $HOME/.ssh/id_rsa-cert.pub


# centos / amazon linux, restart ssh service
sudo systemctl restart sshd

echo "Signing SSH client key done."

# You should be able to ssh into a target host:
# ssh -i signed-cert.pub -i ~/.ssh/id_rsa username@10.0.23.5