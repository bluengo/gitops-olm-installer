SHELL := /bin/bash
LOGFMT := "$(shell date --utc '+%Y-%m-%d--%H-%M-%S').log"
LOGFILE ?= "$(shell mktemp -d)/$(LOGFMT)"


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
	@. scripts/install-gitops-operator.sh | tee -a $(LOGFILE)

# Mirror the IIB image from registry.redhat.com to personal quay.io.
mirror-iib:
ifndef IIB_ID
	$(error ERROR: You need to provide the IIB_ID)
endif
	@. scripts/mirror-iib-to-quay.sh | tee -a $(LOGFILE)

# Copy the registry credential info to the cluster secret.
set-registry-credentials:
	@. scripts/set-registry-credentials.sh | tee -a $(LOGFILE)

# All
all: mirror-iib set-registry-credentials install-gitops-operator

