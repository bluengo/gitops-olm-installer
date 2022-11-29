SHELL := /bin/bash

# Targets.
.PHONY: install-gitops-operator mirror-iib set-registry-credentials all

# Install GitOps operator using OLM.
install-gitops-operator:
ifndef IIB_ID
	$(error ERROR: You need to provide the IIB_ID)
endif
ifndef QUAY_USER
	$(error ERROR: You need to provide the QUAY_USER)
endif
ifndef GITOPS_VERSION
	$(error ERROR: You need to provide the GITOPS_VERSION)
endif
	@. scripts/install-gitops-operator.sh

# Mirror the IIB image from registry.redhat.com to personal quay.io.
mirror-iib:
ifndef IIB_ID
	$(error ERROR: You need to provide the IIB_ID)
endif
	@. scripts/mirror-iib-to-quay.sh

set-registry-credentials:
	@. scripts/set-registry-credentials.sh

# All
all: mirror-iib set-registry-credentials install-gitops-operator

