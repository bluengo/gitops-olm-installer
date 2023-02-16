SHELL := /bin/bash
LOGFMT := "$(shell date --utc '+%Y-%m-%d--%H-%M-%S').log"
LOGFILE ?= "$(shell mktemp -d)/$(LOGFMT)"

RED =\e[91m#  Red color
GRN =\e[92m#  Green color
BLU =\e[96m#  Blue color
YLW =\e[93m#  Yellow color
BLD =\e[1m#   Bold
RST =\e[0m#   Reset format

# Function to print help
define print_help
	@echo -e "\n$(BLD)Targets for this Makefile:$(RST)"
	@echo -e "\tmake $(BLU)mirror-iib$(RST)     $(YLW)<your$(RST)"
	@echo -e "\tmake $(GRN)deploy-ocp-regular-aws$(RST)    Deploy a regular OCP cluster at provided $(YLW)OCP_VER$(RST) in AWS"
	@echo -e "\tmake $(GRN)deploy-ocp-proxy$(RST)          Deploy a proxy OCP cluster at provided $(YLW)OCP_VER$(RST) in AWS"
	@echo -e "\tmake $(GRN)deploy-ocp-disconnected$(RST)   Deploy an air-gapped OCP cluster at provided $(YLW)OCP_VER$(RST) in AWS"
	@echo -e "\tmake $(RED)destroy-cluster$(RST)           Destroys existent cluster provided by $(BLU)NAME$(RST)"
	@echo -e "\n$(BLD)Variables:$(RST)"
	@echo -e "\t$(YLW)OCP_VER$(RST)                        The OCP version of for the new cluster to be created"
	@echo -e "\t$(BLU)NAME$(RST)                           The name of the cluster that is about to be created/destroyed"
	@echo -e "\n  [Optional]:"
	@echo -e "\tBOOTSTRAP_CLUSTER              Is the OCP cluster where plumbing-gitops pipelines is installed. By default: $(BOOTSTRAP_CLUSTER)"
	@echo -e "\n$(BLD)How to use it:$(RST)"
	@echo -e "\t1) First \"oc login\" into the BOOTSTRAP_CLUSTER to have access to the pipelines"
	@echo -e "\t2) Set the needed variables in front of the make command and run your desired target. For instance:"
	@echo -e "\t\t$(YLW)OCP_VER$(RST)=\"stable-4.8\" $(BLU)NAME$(RST)=\"my-ocp-cluster\" $(BLD)make $(GRN)deploy-ocp-regular-psi$(RST)\n"
endef

.PHONY: help
help:

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
deploy: mirror-iib set-registry-credentials install-operator

 
