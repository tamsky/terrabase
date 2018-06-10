# -*- Makefile -*-

# Things that must be declared before including this .makefile:
#
# Vars:
#    $(TF)
# Targets:
#    check

update get init: check ## Download and install modules for the configuration
	KEEP_CACHE=false $(TF) init

plan-local local-plan local-plan-save:
	TERRABASE_LOCAL=local TF_LOG="$(TF_LOG)" ARGS="$(ARGS)" $(MAKE) plan 

plan-nosave: check get ## Generate and show an execution plan
	$(TF) plan $(ARGS)

plan-save plan: check get ## Generate and show an execution plan, and save locally
	rm -f $$PWD/saved-plan
	$(TF) plan -out=$$PWD/saved-plan $(ARGS)

plan-deep: check get ## Generate and show a detailed execution plan, and save locally
	rm -f $$PWD/saved-plan
	$(TF) plan -out=$$PWD/saved-plan -module-depth=-1 $(ARGS)

plan-summary: check get ## Generate a summary output, do not save locally
	$(TF) plan -no-color 2>&1 | grep --color=none -e '^[[:space:]]*[~+-].*' -e ^Plan -e '^Terraform will perform' -e '^Resource actions'

plan-destroy: check get ## Generate and show a plan for DESTRUCTION, and save locally
	rm -f $$PWD/saved-plan
	$(TF) plan -destroy -out=$$PWD/saved-plan $(ARGS)

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

plan-detailed-exitcode: check ## Generate a plan and write $? to './.exitcode'
	rm -f $$PWD/.exitcode
	set +e ; \
	$(TF) plan -out=$$PWD/saved-plan -detailed-exitcode $(ARGS) ; \
            EXITCODE=$$? ; \
            echo $$EXITCODE >$$PWD/.exitcode ; \
            echo terraform exitcode was: $$EXITCODE ; \
            [[ $$EXITCODE -eq 2 ]] && exit 0 ; \
            exit $$EXITCODE

apply: check get ## Builds or changes infrastructure
	rm -f $$PWD/saved-plan
	$(TF) plan -out=$$PWD/saved-plan $(ARGS)
	$(TF) apply $(ARGS) $$PWD/saved-plan

unsafe-apply: check get ## Builds or changes infrastructure
	rm -f $$PWD/saved-plan
	$(TF) apply $(ARGS)

apply-saved-plan: check ## Builds or changes infrastructure based on saved plan, no 'get' required.
	$(TF) apply $(ARGS) $$PWD/saved-plan && mv -f $$PWD/saved-plan $$PWD/saved-plan.applied

destroy: check get ## Destroy Robinson family, DESTROY!!
	rm -f $$PWD/saved-plan
	$(TF) plan -destroy -out=$$PWD/saved-plan $(ARGS)
	@echo -n "Hit ^C now to cancel, or press return TO DESTROY. ARE YOU SURE?" ; read something
	$(TF) apply $$PWD/saved-plan

unsafe-destroy: check get ## Destroy Robinson family, DESTROY!!
	rm -f $$PWD/saved-plan
	$(TF) plan -destroy -out=$$PWD/saved-plan $(ARGS)
	$(TF) apply $$PWD/saved-plan

graph: check ## Generate graph.png of TF depednencies
	$(TF) graph --draw-cycles | dot -T png > graph.png
	echo created $(PWD)/graph.png

graph-saved-plan: check ## Generate graph.png of TF depednencies
	$(TF) graph --draw-cycles $$PWD/saved-plan | dot -T png > graph.png
	echo created $(PWD)/graph.png

show-plan: check ## Show current TF state
	$(TF) show $$PWD/saved-plan $(ARGS)

show: check ## Show current TF state
	$(TF) show $(ARGS)

taint: check ## Taints the one or more things listed in ARGS
	$(TF) taint $(ARGS)

console: check ## Interactive TF interpolation shell, debug *.tf constructs
	$(TF) console $(ARGS)

cache-plugins:
	$(MAKE) -C $(UPSTREAM_ROOT_PREFIX)../../lib/load-plugins-dir internal-cache-plugins

# TODO
# state-list
# state-rm

## Use the template directory to populate a new directory.
## Only creates a new directory for the current environment.
## TODO(mtamsky): improve to create in all environments.
new-directory: check
	@[[ -f .environment_root ]] && cd template ; \
	/bin/echo -n "New directory name? " ; read newdir ; \
          [[ -d ../$${newdir}/ ]] || { echo copying template files to $${newdir} ; \
          rsync -avP ../template/ ../$${newdir}/ ; } \
          ; \
          [[ -d ../../aws/$${newdir}/ ]] || { \
            echo copying blueprint files from //aws to //aws/$${newdir} ; \
            rsync -avP ../../aws/template/ ../../aws/$${newdir}/ ; \
            gsed -i -e "s/__ROLE_NAME__/$${newdir}/" ../../aws/$${newdir}/role-name.tf ; }


## Use the template-elb-service directory to populate a new directory.
## Only creates a new directory for the current environment.
## TODO(mtamsky): improve to create in all environments.
new-alb-directory: check
	@[[ -f .environment_root ]] && cd template-alb-service ; \
	/bin/echo -n "New ALB service directory name? " ; read newdir ; \
          [[ -d ../$${newdir}/ ]] || { \
            echo copying template files to $${newdir} ; \
            rsync -avP ../template-alb-service/ ../$${newdir}/ ; } \
          ; \
          [[ -d ../../aws/$${newdir}/ ]] || { \
            echo copying blueprint files from //aws to //aws/$${newdir} ; \
            rsync -avP ../../aws/template-alb-service/ ../../aws/$${newdir}/ ; \
            gsed -i -e "s/__ROLE_NAME__/$${newdir}/" ../../aws/$${newdir}/role-name.tf ; }


## Use the template-example-asg directory to populate a new directory.
## This is not typically what you want to use... 'new-alb-directory' is preferred.
## Only creates a new directory for the current environment.
## TODO(mtamsky): improve to create in all environments.
new-example-asg-directory: check
	@[[ -f .environment_root ]] && cd template-alb-service ; \
	/bin/echo -n "New EXAMPLE AutoScaleGroup service directory name? " ; read newdir ; \
          [[ -d ../$${newdir}/ ]] || { \
            echo copying template files to $${newdir} ; \
            rsync -avP ../template-example-asg/ ../$${newdir}/ ; } \
          ; \
          [[ -d ../../aws/$${newdir}/ ]] || { \
            echo copying blueprint files from //aws to //aws/$${newdir} ; \
            rsync -avP ../../aws/template-example-asg/ ../../aws/$${newdir}/ ; \
            gsed -i -e "s/__ROLE_NAME__/$${newdir}/" ../../aws/$${newdir}/role-name.tf ; }


## Auto help from: http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help:
	@grep -h -E '^[a-zA-Z_%-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
