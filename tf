#!/bin/bash

set -e
# If terraform debugging is requested, turn on debug here too:
[[ $TF_LOG ]] && set -x

# START OF MAIN
[[ $1 = "check" ]] && { echo "Terrabase Terraform Helper Script Version: 0.1" ; exit 0 ; }

DATE=${DATE:-$(date +%D)}
export TF_VAR_username=$USER
export TF_VAR_date="$DATE"

# this file is next to the Makefile being run, so this is the correct path:
source ./environment.sh

[[ "${KEEP_CACHE}" == false ]] && TERRAGRUNT_FORCE_DOWNLOAD_FLAG=--terragrunt-source-update

exec /usr/bin/env terragrunt "$@" ${TERRAGRUNT_FORCE_DOWNLOAD_FLAG}
# Note: TERRAGRUNT_*_FLAGs must appear AFTER the commands
# (https://github.com/gruntwork-io/terragrunt/issues/150)
