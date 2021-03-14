#!/bin/bash

# Build all required amis.
set -e # Exit on error

$TF_VAR_firehawk_path/../packer-firehawk-amis/modules/firehawk-base-ami/build.sh
$TF_VAR_firehawk_path/../packer-firehawk-amis/modules/firehawk-ami/build.sh