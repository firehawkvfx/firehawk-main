#!/bin/bash

# Build all required amis.
set -e # Exit on error

$TF_VAR_firehawk_path/modules/terraform-aws-vault/examples/vault-consul-ami/build.sh