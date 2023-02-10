SHELL := /bin/bash
LOGFMT := "$(shell date --utc '+%Y-%m-%d--%H-%M-%S').log"
LOGFILE ?= "$(shell mktemp -d)/$(LOGFMT)"


.PHONY: install-operator
# Install GitOps operator using OLM.
install-operator:
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


.PHONY: mirror-iib
# Mirror the IIB image from registry.redhat.com to personal quay.io.
mirror-iib:
ifndef IIB_ID
	$(error ERROR: You need to provide the IIB_ID)
endif
	@. scripts/mirror-iib-to-quay.sh | tee -a $(LOGFILE)


.PHONY: set-registry-credentials
# Copy the registry credential info to the cluster secret.
set-registry-credentials:
	@. scripts/set-registry-credentials.sh | tee -a $(LOGFILE)

.PHONY: deploy
# Deploy GitOps operator, as well as all the needed resources (credentials, iib...)
deploy:
	$(MAKE) mirror-iib || $(error ERROR when mirroring IIB)
	$(MAKE) set-registry-credentials || $(error ERROR when setting up brew credentials)
	$(MAKE) install-operator || $(error ERROR when trying to install operator)

