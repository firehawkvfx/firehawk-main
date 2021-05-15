#!/bin/bash

set -e

echo "...Retrieve public key from SSM parameter store"

if [[ -z "$TF_VAR_resourcetier" ]]; then
  echo "TF_VAR_resourcetier is not defined.  Ensure you have run source ./update_vars.sh"
fi

parm_name="/firehawk/resourcetier/${TF_VAR_resourcetier}/onsite_user_public_key"

get_parms=$(aws ssm get-parameters --names ${parm_name})
invalid=$(echo ${get_parms} | jq -r .'InvalidParameters | length')

if [[ $invalid -eq 1 ]]; then # Init if not set
    echo "...Failed retrieving: ${parm_name}"
    exit 1
else
    echo "Result: ${get_parms}"
    value=$(echo ${get_parms} | jq -r '.Parameters[0].Value')

    echo "$value" | tee ~/.ssh/remote_host/id_rsa.pub
fi