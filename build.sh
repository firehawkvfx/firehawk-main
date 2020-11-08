#!/bin/bash

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )" # The directory of this script


# Build all required amis.
set -e # Exit on error
$SCRIPTDIR/modules/terraform-aws-vault/examples/bastion-ami/build.sh
$SCRIPTDIR/modules/terraform-aws-vault/examples/nice-dcv-ami/build.sh