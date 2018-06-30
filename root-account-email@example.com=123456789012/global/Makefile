### name of the directory containing this Makefile,
# ( used to name the S3 storage key for this component's terraform remote config)
UPSTREAM_ROOT_PREFIX := $(shell FILE=.environment_root ; for i in . .. ../.. ../../.. ; do test -e $$i/$$FILE && echo "$$i/" && exit 0 ; done ; echo "unable-to-find-$$FILE" ; exit 1 )

SHELL := /bin/bash -e

TF := $(UPSTREAM_ROOT_PREFIX)../../tf

all: enable-remote-state update ## Configure this module for Terraforming

include $(UPSTREAM_ROOT_PREFIX)../../lib/environment.sh-and-enable-remote-state.makefile
include $(UPSTREAM_ROOT_PREFIX)../../lib/check.makefile
include $(UPSTREAM_ROOT_PREFIX)../../lib/common-build-targets.makefile

.PHONY: spin-up tear-down

spin-up: environment.sh
	. environment.sh && KEEP_CACHE=false $(TF) spin-up

tear-down: environment.sh
	. environment.sh && KEEP_CACHE=false $(TF) tear-down
