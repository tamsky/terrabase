# name of the directory containing this Makefile,
# ( used to name the S3 storage key for this component's terraform remote config)
COMPONENT := $(lastword $(subst /, ,$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))))

SHELL := $(SHELL) -e

TF := ../../tf

all: enable-remote-state update ## Configure this module for Terraforming

include ../../lib/environment.sh-and-enable-remote-state.makefile
include ../../lib/check.makefile
include ../../lib/common-build-targets.makefile
