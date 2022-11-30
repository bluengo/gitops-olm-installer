#!/usr/bin/env bash
#
# Install GitOps operator using OLM from a custom IIB

## Import common
#  This script is intended to be called from the 
#  Makefile in the root dir, so the path is relative
#  to that root dir.
source "scripts/common.sh"

## TRAP
trap 'trap_exit ${?}' EXIT SIGINT SIGTERM
trap 'trap_err ${?} ${LINENO} ${BASH_LINENO} ${BASH_COMMAND} $(printf "::%s" ${FUNCNAME[@]:-})' ERR

## Variables
needed_commands=("oc" "envsubst")
needed_vars=("IIB_ID" "QUAY_USER" "GITOPS_VERSION")
###################################################

##RUN
log_info "Checking dependencies"
check_dependencies "${needed_commands[@]}" || exit_on_err 1 "Dependencies not met"
log_info "Checking variables"
check_variables "${needed_vars[@]}" || exit_on_err 2 "Please, provide the required variables"

# Print information
log_ok "All variables are present:"
log_info "IIB_ID=${IIB_ID}"
log_info "QUAY_USER=${QUAY_USER}"
log_info "GITOPS_VERSION=${GITOPS_VERSION}"

# ImageContentSourcePolicy:
# ·························
# Since the regular RedHat registry is not available, we
# create this object to make the cluster look into brew
# registry instead
log_info "Installing ImageContentSourcePolicy 'brew-registry'"
{
  envsubst < "manifests/01-ImageContentSourcePolicy.yaml" | oc apply -f - &&\
  log_ok "ImageContentSourcePolicy created successfully";
} || {
  exit_on_err 3 "Unable to create ImageContentSourcePolicy to point brew registry"
}

# CatalogSource:
# ··············
# The catalogsource object provides an alternative source
# to install operators, in this case, instead of using
# the marketplace, we add operators from a custom IIB.
log_info "Installing CatalogSource 'iib-${QUAY_USER}' with IIB 'quay.io/${QUAY_USER}/iib:${IIB_ID}'"
{
  envsubst < "manifests/02-CatalogSource.yaml" | oc apply -f - &&\
  log_ok "CatalogSource created successfully";
} || {
  exit_on_err 4 "Unable to create CatalogSource for IIB ${IIB_ID}"
}

# Subscription:
# ·············
# Last step is to create a subscription within the above
# catalog source to install GitOps operator from the 
# channel specified by $GITOPS_VERSION.
log_info "Installing Subscription 'openshift-gitops-operator' to the CatalogSource"
log_info "Channel: gitops-${GITOPS_VERSION}"
{
  envsubst < "manifests/03-Subscription.yaml" | oc apply -f - &&\
  log_ok "Subscription created successfully";
} || {
  exit_on_err 5 "Unable to create Subscription 'openshift-gitops-operator'"
}

