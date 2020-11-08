#!/bin/bash

# Build all required amis.
set -e # Exit on error
firehawk-main/modules/terraform-aws-vault/examples/bastion-ami/build.sh
firehawk-main/modules/terraform-aws-vault/examples/nice-dcv-ami/build.sh