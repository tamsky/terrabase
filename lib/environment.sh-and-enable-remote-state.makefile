
UPSTREAM_ENVIRONMENT_TF_JSON := $(shell FILE=environment.tf.json ; for i in . .. ../.. ../../.. ; do test -e $$i/$$FILE && echo "$$i/$$FILE" && exit 0 ; done ; echo "unable-to-find-$$FILE" ; exit 1)
UPSTREAM_ROOT_PREFIX := $(shell FILE=.environment_root ; for i in . .. ../.. ../../.. ; do test -e $$i/$$FILE && echo "$$i/" && exit 0 ; done ; echo "unable-to-find-$$FILE" ; exit 1)

##
# Build a .sh file that declares these values from the .json
##
#environment.sh: ## Build a .sh file that declares these values from the .json
environment.sh: $(UPSTREAM_ENVIRONMENT_TF_JSON) $(lastword $(MAKEFILE_LIST)) ## Build a .sh file that declares these values from the .json
	@/bin/echo -n Generating local ./environment.sh file
	@rm -f $@
	@echo export ENVIRONMENT=$$(jq -r '.["variable"]["environment"]["default"] // empty' <$<) >> $@
	@echo export TERRABASE_UPSTREAM_ENVIRONMENT_TF_JSON="$(UPSTREAM_ENVIRONMENT_TF_JSON)" >> $@
	@echo export TERRABASE_UPSTREAM_ROOT_PREFIX="$(UPSTREAM_ROOT_PREFIX)" >> $@

	@echo ... done

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
