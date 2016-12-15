# Requires $(TF) is already set.

# Example of a way to inject per-environment Makefile variables
# include ../variables.makefile

credentials-checks: environment.sh
	@source environment.sh ; \
	    [[ -z $${AWS_DEFAULT_REGION} ]] || { echo AWS_DEFAULT_REGION environment variable need to be NOT SET - It overrides values in variables.tf, which can be bad.; exit 1; } ; \
	    [[ $$(aws configure get aws_access_key_id --profile $$AWS_CREDENTIALS_PROFILE_NAME) ]] || { echo AWS_ACCESS_KEY_ID credential unavailable from ~/.aws/credentials:[$$AWS_CREDENTIALS_PROFILE_NAME] profile.; exit 1; } ; \
	    [[ $$(aws configure get aws_secret_access_key --profile $$AWS_CREDENTIALS_PROFILE_NAME) ]] || { echo AWS_SECRET_ACCESS_KEY credential unavailable from ~/.aws/credentials:[$$AWS_CREDENTIALS_PROFILE_NAME] profile.; exit 1; }
        # AWS credentials ok.

script-checks:
        # Check that our terraform script is being used:
	@$(TF) check >/dev/null || { echo "terraform helper script missing" ; exit 1 ; }

binary-checks:
        # Check for required binaries
	@type terraform >/dev/null || { echo "terraform binary missing, install with 'brew install terraform'" ; exit 1;}
	@type terragrunt >/dev/null || { echo "terragrunt binary missing, install with 'brew install terragrunt'" ; exit 1;}
	@test -e .terragrunt || { echo "dot-terragrunt (./.terragrunt) file is missing, did you forget to copy it when you created this directory?" ; exit 1;}

# ordered list of dependencies to check:
check:  binary-checks script-checks credentials-checks enable-remote-state ## Check that the whole TF config is ready to go

toplevel-makefile-check:

