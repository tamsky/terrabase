
UPSTREAM_ENVIRONMENT_TF_JSON := $(shell FILE=environment.tf.json ; for i in . .. ../.. ../../.. ; do test -e $$i/$$FILE && echo "$$i/$$FILE" && exit 0 ; done ; echo "unable to find $$FILE" )

##
# Build a .sh file that declares these values from the .json
##
#environment.sh: ## Build a .sh file that declares these values from the .json
environment.sh: $(UPSTREAM_ENVIRONMENT_TF_JSON) $(lastword $(MAKEFILE_LIST)) ## Build a .sh file that declares these values from the .json
	@/bin/echo -n Generating local ./environment.sh file
	@rm -f $@
	@echo export AWS_CREDENTIALS_PROFILE_NAME=$$(jq -r '.["variable"]["aws_credentials_profile_name"]["default"] // empty' <$<) >> $@
	@echo export AWS_REGION=$$(jq -r '.["provider"]["aws"]["region"] // empty' <$<) >> $@
	@echo export ENVIRONMENT=$$(jq -r '.["variable"]["environment"]["default"] // empty' <$<) >> $@
	@echo export REMOTE_STATE_S3_STORAGE_BUCKET=$$(jq -r '.["variable"]["tf_remote_state_s3_storage_bucket"]["default"] // empty' <$<) >> $@
	@echo export REMOTE_STATE_S3_STORAGE_REGION=$$(jq -r '.["variable"]["tf_remote_state_s3_storage_region"]["default"] // empty' <$<) >> $@
	@echo export AWS_ACCESS_KEY_ID=\$$\(aws configure get aws_access_key_id --profile \$${AWS_CREDENTIALS_PROFILE_NAME}\) >> $@
	@echo export AWS_SECRET_ACCESS_KEY=\$$\(aws configure get aws_secret_access_key --profile \$${AWS_CREDENTIALS_PROFILE_NAME}\) >> $@

	@echo ... done

# Terragrunt is handling this:
##
# Enables terraform remote config for S3
# Sets the S3 storage key to: $$ENVIRONMENT-$COMPONENT
# eg. "dev-core", "staging-servicename", "prod-media-server"
##
# .terraform/terraform.tfstate: environment.sh ## Enables terraform remote config for S3
# 	source environment.sh ; \
#             [[ $$ENVIRONMENT ]] && \
#             [[ ${COMPONENT} ]] && \
#             [[ $$REMOTE_STATE_S3_STORAGE_BUCKET ]] && \
#             [[ $$REMOTE_STATE_S3_STORAGE_REGION ]] && \
#             set -x && \
#             #setup aws ENV credentials from aws commands:
#             AWS_ACCESS_KEY_ID=$(aws configure get access_key) ...
#             terraform remote config -pull=$${PULL:-true} -backend=S3 \
#                 -backend-config=key=$$ENVIRONMENT-${COMPONENT} \
#                 -backend-config=bucket=$$REMOTE_STATE_S3_STORAGE_BUCKET \
#                 -backend-config=region=$$REMOTE_STATE_S3_STORAGE_REGION

check-if-state-is-local:
	@[[ -f TFSTATE-IS-LOCAL ]] && { echo "Please use '../../tf' commands when TFSTATE-IS-LOCAL" ; exit 1 ; } || true

# If the remote state file is missing
# then it needs to be created by running 'terraform remote config ..."
# this would be where we trigger it, but terragrunt handles it now.
enable-remote-state: check-if-state-is-local environment.sh

start-dirty-touch:
# TODO: add terragrunt locking
	$(TF) remote config -disable
	touch TFSTATE-IS-LOCAL

finish-dirty-touch:
# TODO: remove terragrunt locking
	$(MAKE) PULL=false .terraform/terraform.tfstate
	rm -f TFSTATE-IS-LOCAL
