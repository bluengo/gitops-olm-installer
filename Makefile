SHELL := /bin/bash
LOGFMT := $(shell date --utc '+%Y-%m-%d--%H-%M-%S').log
LOGFILE ?= $(shell mktemp -d)/$(LOGFMT)

RED =\e[91m#  Red color
GRN =\e[92m#  Green color
BLU =\e[96m#  Blue color
YLW =\e[93m#  Yellow color
BLD =\e[1m#   Bold
RST =\e[0m#   Reset format

# Function to print help
define print_help
	@echo -e "\n$(BLD)Targets for this Makefile:$(RST)"
	@echo -e "\tmake $(BLU)mirror-iib$(RST)\t\t\tMirror an $(YLW)IIB$(RST) to quay.io/${QUAY_USER}/iib"
	@echo -e "\tmake $(BLU)set-registry-credentials$(RST)\tSet your brew registry credentials in the OCP's pull-secret secret"
	@echo -e "\tmake $(GRN)install-operator$(RST)\t\tInstall OpenShift GitOps using Operator Lifecycle Manager"
	@echo -e "\tmake $(GRN)deploy$(RST)\t\t\tRuns mirror-iib, set-registry-credentials and install-operator by order"
endef

.PHONY: help
help:
	$(print_help)

.PHONY: install-operator
# Install GitOps operator using OLM.
install-operator:
ifndef IIB_ID
	@echo "No IIB_ID was provided, so installing from 'redhat-operators' CatalogSource"
endif
ifndef QUAY_USER
	$(error ERROR: You need to provide the QUAY_USER)
endif
ifndef GITOPS_VERSION
	@echo "No GITOPS_VERSION was provided, so installing 'latest' operator"
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
deploy: mirror-iib set-registry-credentials install-operator

 
