# Requires $(TF) is already set.

# Example of a way to inject per-environment Makefile variables
# include ../variables.makefile

credentials-checks: environment.sh
	@source environment.sh ; \
	    # [[ -z $${AWS_DEFAULT_REGION} ]] || { echo AWS_DEFAULT_REGION environment variable MUST NOT BE SET - It overrides values in variables.tf, which can be bad.; exit 1; } ;
	    [[ $${USING_IAM_INSTANCE_PROFILE} ]] && exit 0 ; \
	    makefile_check_credential_profile_name=$$(jq -r '.["variable"]["aws_provider_profile_name"]["default"] // .["provider"][0]["aws"]["profile"]' < environment.tf.json) ; \
	    [[ $$(aws configure get aws_access_key_id --profile $$makefile_check_credential_profile_name) ]] || { echo AWS_ACCESS_KEY_ID credential unavailable from ~/.aws/credentials:[$$makefile_check_credential_profile_name] profile.; exit 1; } ; \
	    [[ $$(aws configure get aws_secret_access_key --profile $$makefile_check_credential_profile_name) ]] || { echo AWS_SECRET_ACCESS_KEY credential unavailable from ~/.aws/credentials:[$$makefile_check_credential_profile_name] profile.; exit 1; }
        # AWS credentials ok.

script-checks:
        # Check that our terraform script is being used:
	@$(TF) check >/dev/null || { echo "terraform helper script missing" ; exit 1 ; }

binary-checks:
        # Check for required binaries
	@type terraform >/dev/null || { echo "terraform binary missing, install with 'brew install terraform'" ; exit 1;}
	@type terragrunt >/dev/null || { echo "terragrunt binary missing, install with 'brew install terragrunt'" ; exit 1;}
	@test -e terraform.tfvars || { echo "terraform.tfvars file is missing, it should contain a terragrunt block, did you forget to copy it when you created this directory?" ; exit 1;}


$(UPSTREAM_ROOT_PREFIX)/terragrunt-local-config.tfvars: $(UPSTREAM_ROOT_PREFIX)/terragrunt-local-config.tfvars.in $(UPSTREAM_ROOT_PREFIX)/terragrunt-s3-config.in
	echo "# This file generated by MAKEFILE, changes here will be LOST" >$@
	cat $(UPSTREAM_ROOT_PREFIX)/terragrunt-s3-config.in >>$@
	cat $(UPSTREAM_ROOT_PREFIX)/terragrunt-local-config.tfvars.in >>$@

$(UPSTREAM_ROOT_PREFIX)/terragrunt-default-config.tfvars: $(UPSTREAM_ROOT_PREFIX)/terragrunt-default-config.tfvars.in $(UPSTREAM_ROOT_PREFIX)/terragrunt-s3-config.in
	echo "# This file generated by MAKEFILE, changes here will be LOST" >$@
	cat $(UPSTREAM_ROOT_PREFIX)/terragrunt-s3-config.in >>$@
	cat $(UPSTREAM_ROOT_PREFIX)/terragrunt-default-config.tfvars.in >>$@

toplevel-makefile-check: $(UPSTREAM_ROOT_PREFIX)/terragrunt-default-config.tfvars $(UPSTREAM_ROOT_PREFIX)/terragrunt-local-config.tfvars

# ordered list of dependencies to check:
check:  binary-checks script-checks credentials-checks enable-remote-state toplevel-makefile-check


#
# switch versions
#
switch-to-0.10.8:
	brew switch terraform 0.10.8 ; brew switch terragrunt 0.13.24
switch-to-0.10.5:
	brew switch terraform 0.10.5 ; brew switch terragrunt 0.13.2
# deprecated:
#switch-to-0.10.2:
#	brew switch terraform 0.10.2 ; brew switch terragrunt 0.13.0
#switch-to-0.8.8:
#	brew switch terraform 0.8.8 ; brew switch terragrunt 0.11.0
