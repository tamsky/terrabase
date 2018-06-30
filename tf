#!/bin/bash

set -e
# If terraform debugging is requested, turn on debug here too:
[[ $TF_LOG ]] && set -x

# If not using IAM instance profile, tries to discover and set AWS_PROFILE.
# then, based on active profile, exports environment variable 'AWS_ACCOUNT_ID'.
#
function discover_aws_account_id () {
    if [[ $USING_IAM_INSTANCE_PROFILE = "true" ]] ; then
        # We're using IAM, PROFILE_ARG can be left empty.
        echo "Using IAM credentials."
    elif [[ -f environment.tf.json ]] ; then
        # Per-Environment role directories must declare their profile in environment.tf.json
        local environment_tf_json_provider_aws_profile=$(jq -r '.provider[]|.aws|select(.alias|not)|.profile' < environment.tf.json)
        if [[ $environment_tf_json_provider_aws_profile =~ ^\$\{var.(.+)} ]] ; then
           echo retrieving environment var
           environment_tf_json_provider_aws_profile=$(jq -r ".variable.${BASH_REMATCH[1]}.default" < environment.tf.json)
        fi
                                                             
        export AWS_PROFILE=${AWS_PROFILE:-$environment_tf_json_provider_aws_profile}
        echo using aws profile: ${AWS_PROFILE}
        
        [[ $AWS_PROFILE ]] && PROFILE_ARG="--profile=${AWS_PROFILE}"
    else
        echo Not setting AWS_PROFILE due to lack of environment.tf.json.
    fi

    if [[ $AWS_ACCOUNT_ID ]] ; then
        # /global/* directories, in environment-sprinkles.sh, will pre-define this value:
        # export AWS_ACCOUNT_ID=$(...)
        echo "AWS_ACCOUNT_ID defined by environment: $AWS_ACCOUNT_ID";
    else
        export AWS_ACCOUNT_ID=$(aws sts get-caller-identity ${PROFILE_ARG} --output json | jq -r .Account) ;
        echo found: AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID} ;
    fi
}

# START OF MAIN
[[ $1 = "check" ]] && { echo "Terrabase Terraform Helper Script Version: 0.1" ; exit 0 ; }

DATE=${DATE:-$(date +%D)}
export TF_VAR_username=$USER
export TF_VAR_date="$DATE"

# this file is next to the Makefile being run, so this is the correct path:
source ./environment.sh

# At this point, we should have valid AWS env vars to fetch the AWS_ACCOUNT_ID.
#
# We need this value in order to give terragrunt enough information to
# assemble the full remote_state bucket name.  This name can only be passed
# during 'terraform init', which is, necessarily, before running terraform.
discover_aws_account_id


[[ "${KEEP_CACHE}" == false ]] && TERRAGRUNT_FORCE_DOWNLOAD_FLAG=--terragrunt-source-update

exec /usr/bin/env terragrunt "$@" ${TERRAGRUNT_FORCE_DOWNLOAD_FLAG}
# Note: TERRAGRUNT_*_FLAGs must appear AFTER the commands
# (https://github.com/gruntwork-io/terragrunt/issues/150)
