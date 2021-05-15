#!/bin/bash

set -e

echo "...Post cert to SSM parameter store."

parm_name="/firehawk/resourcetier/${TF_VAR_resourcetier}/onsite_user_public_cert"

cert_path="/home/ec2-user/.ssh/remote_host/id_rsa-cert.pub"

if [[ ! -f "$cert_path" ]]; then # Init if not set
    echo "...Failed retrieving: $cert_path}"
    exit 1
else
    value=$(cat $cert_path)
    aws ssm put-parameter \
        --name "${parm_name}" \
        --type "String" \
        --value "${value}" \
        --overwrite
fi