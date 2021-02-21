#!/bin/bash

echo "Configure known hosts to avoid Trust On First Use warnings."

set -e

aws_external_domain=$TF_VAR_aws_external_domain
trusted_ca="/etc/ssh/trusted-user-ca-keys.pem"
# Aquire the public CA cert to approve an authority
vault read -field=public_key ssh-client-signer/config/ca | sudo tee $trusted_ca
if sudo test ! -f "$trusted_ca"; then
    echo "Missing $trusted_ca"
    exit 1
fi

# If TrustedUserCAKeys not defined, then add it to sshd_config
sudo grep -q "^TrustedUserCAKeys" /etc/ssh/sshd_config || echo 'TrustedUserCAKeys' | sudo tee --append /etc/ssh/sshd_config
# Ensure the value for TrustedUserCAKeys is configured correctly
sudo sed -i "s@TrustedUserCAKeys.*@TrustedUserCAKeys $trusted_ca@g" /etc/ssh/sshd_config 

# Add the CA cert to use it for known host verification
# curl http://vault.service.consul:8200/v1/ssh-host-signer/public_key
key=$(vault read -field=public_key ssh-host-signer/config/ca)

ssh_known_hosts_path=/etc/ssh/ssh_known_hosts
if sudo test ! -f $ssh_known_hosts_path; then
    echo "Creating $ssh_known_hosts_path"
    sudo touch $ssh_known_hosts_path # ensure known hosts file exists
fi

if [[ "$OSTYPE" == "darwin"* ]]; then # Acquire file permissions.
    octal_permissions=$(sudo stat -f %A "$ssh_known_hosts_path" | rev | sed -E 's/^([[:digit:]]{4})([^[:space:]]+)/\1/' | rev ) # clip to 4 zeroes
else
    octal_permissions=$(sudo stat --format '%a' "$ssh_known_hosts_path" | rev | sed -E 's/^([[:digit:]]{4})([^[:space:]]+)/\1/' | rev) # clip to 4 zeroes
fi
octal_permissions=$( python -c "print( \"$octal_permissions\".zfill(4) )" ) # pad to 4 zeroes
echo "$ssh_known_hosts_path octal_permissions currently $octal_permissions."
if [[ "$octal_permissions" != "0644" ]]; then
    echo "...Setting to 0644"
    sudo chmod 0644 $ssh_known_hosts_path
fi

# init the cert auth line
sudo grep -q "^@cert-authority \*\.consul" $ssh_known_hosts_path || echo "@cert-authority *.consul,*.$aws_external_domain" | sudo tee --append $ssh_known_hosts_path
sudo sed -i "s#@cert-authority \*\.consul.*#@cert-authority *.consul,*.$aws_external_domain $key#g" $ssh_known_hosts_path

echo "Added CA to $ssh_known_hosts_path."
sudo systemctl restart sshd
echo "Configure signed known hosts done."

### End sign SSH host key