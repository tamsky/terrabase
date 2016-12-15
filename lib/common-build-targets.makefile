# -*- Makefile -*-

# Things that must be declared before including this .makefile:
#
# Vars:
#    $(TF)
# Targets:
#    check

update get: check ## Download and install modules for the configuration
	$(TF) get -update

plan-nosave: check get ## Generate and show an execution plan
	$(TF) plan $(ARGS)

plan-save plan: check get ## Generate and show an execution plan, and save locally
	rm -f saved-plan
	$(TF) plan -out=saved-plan $(ARGS)

plan-deep: check get ## Generate and show a detailed execution plan, and save locally
	rm -f saved-plan
	$(TF) plan -out=saved-plan -module-depth=-1 $(ARGS)

plan-destroy: check get ## Generate and show a plan for DESTRUCTION, and save locally
	rm -f saved-plan
	$(TF) plan -destroy -out=saved-plan $(ARGS)

plan-targets: check ## Generate a plan for (more or less) ONLY_INSTANCE target. (eg: make plan-targets ONLY_INSTANCE=0)
# Accepted args: ARGS ONLY_INSTANCE
#
#   convert +-~ lines of output to --target= refs
#
	@$(TF) get -update &>/dev/null
	@$(TF) plan -no-color $(ARGS) | \
	  egrep -e '^(~|-/\+|\+) .+' | \
	  gawk '{print $$NF}' | \
	  gawk '/\.'"$${ONLY_INSTANCE:-[0-9]+}"'$$/ \
              { printf "--target=" gensub(/^(.+)\.('"$${ONLY_INSTANCE:-[0-9]+}"')$$/,"\\1[\\2]","g") " " } \
                /-all$$/ \
              { printf "--target=" gensub(/^(.+)-all$$/,"\\1-all","g") " "}' && \
	  echo

apply: check get ## Builds or changes infrastructure
	rm -f saved-plan
	$(TF) plan -out=saved-plan $(ARGS)
	$(TF) apply $(ARGS) saved-plan

apply-saved-plan: check get ## Builds or changes infrastructure based on saved plan
	$(TF) apply $(ARGS) saved-plan && mv -f saved-plan saved-plan.applied

destroy: check get ## Destroy Robinson family, DESTROY!!
	rm -f saved-plan
	$(TF) plan -destroy -out=saved-plan $(ARGS)
	@echo -n "Hit ^C now to cancel, or press return TO DESTROY. ARE YOU SURE?" ; read something
	$(TF) apply saved-plan

unsafe-destroy: check get ## Destroy Robinson family, DESTROY!!
	rm -f saved-plan
	$(TF) plan -destroy -out=saved-plan $(ARGS)
	$(TF) apply saved-plan

graph: check ## Generate graph.png of TF depednencies
	$(TF) graph --draw-cycles | dot -T png > graph.png
	echo created $(PWD)/graph.png

graph-saved-plan: check ## Generate graph.png of TF depednencies
	$(TF) graph --draw-cycles saved-plan | dot -T png > graph.png
	echo created $(PWD)/graph.png

show: check ## Show current TF state
	$(TF) show .terraform/terraform.tfstate

taint: check ## Taints the one or more things listed in ARGS
	$(TF) taint $(ARGS)

## Auto help from: http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help:
	@grep -h -E '^[a-zA-Z_%-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
