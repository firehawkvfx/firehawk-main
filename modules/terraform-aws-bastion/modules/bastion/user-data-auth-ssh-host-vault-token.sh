#!/bin/bash

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

function has_yum {
  [[ -n "$(command -v yum)" ]]
}

if $(has_yum); then
    hostname=$(hostname -s) # in centos, failed dns lookup can cause commands to slowdown
    echo "127.0.0.1   $hostname.${aws_domain} $hostname" | tee -a /etc/hosts
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