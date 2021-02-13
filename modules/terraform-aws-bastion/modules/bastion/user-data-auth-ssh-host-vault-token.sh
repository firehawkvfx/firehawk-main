#!/bin/bash
# This script is meant to be run in the User Data of each EC2 Instance while it's booting. The script uses the
# run-consul script to configure and start Consul in client mode. Note that this script assumes it's running in an AMI
# built from the Packer template in examples/vault-consul-ami/vault-consul.json.

set -e

# Send the log output from this script to user-data.log, syslog, and the console
# From: https://alestic.com/2010/12/ec2-user-data-output/
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

# Log the given message. All logs are written to stderr with a timestamp.
function log {
 local -r message="$1"
 local -r timestamp=$(date +"%Y-%m-%d %H:%M:%S")
 >&2 echo -e "$timestamp $message"
}

# log "Reconfigure network insterfaces..."
# rm -fr /etc/sysconfig/network-scripts/ifcfg-eth0 # this may need to be removed from the image. having a leftover network interface file here if the interface is not present can cause dns issues and slowdowns with sudo.

# yum install -y NetworkManager
# systemctl disable NetworkManager
# systemctl status NetworkManager  # -> inactive
# systemctl stop network
# systemctl start network
# # systemctl start NetworkManager
# systemctl start network.service
# systemctl start network

function has_yum {
  [[ -n "$(command -v yum)" ]]
}

if $(has_yum); then
    hostname=$(hostname -s) # in centos, failed dns lookup can cause commands to slowdown
    echo "127.0.0.1   $hostname.${aws_domain} $hostname" | tee -a /etc/hosts
    # hostnamectl set-hostname $hostname.${aws_domain} # Red hat recommends that the hostname uses the FQDN.  hostname -f to resolve the domain may not work at this point on boot, so we use a var.
    # systemctl restart network
fi

log "hostname: $(hostname)"
log "hostname: $(hostname -f) $(hostname -s)"

log "test sudo delay"
log "no sudo"
sudo echo "sudo"
log "sudo"
log "no sudo"
sudo echo "sudo"
log "sudo"
log "no sudo"