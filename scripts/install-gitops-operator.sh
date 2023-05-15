#!/usr/bin/env bash
#
# Install GitOps operator using OLM from a custom IIB

## Import common
#  This script is intended to be called from the 
#  Makefile in the root dir, so the path is relative
#  to that root dir.
source "scripts/common.sh"

## TRAP
trap 'trap_exit ${BASH_SOURCE} ${?}' EXIT SIGINT SIGTERM
trap 'trap_err ${?} ${LINENO} ${BASH_LINENO} ${BASH_COMMAND} $(printf "::%s" ${FUNCNAME[@]:-})' ERR

## Variables
needed_commands=("oc" "envsubst")

## Functions
disable_default_sources() {
  # Disable all default sources to avoid OLM installing from marketplace
  log_info "Patching cluster config to disable default sources"
  {
    oc patch operatorhub.config.openshift.io/cluster -p='{"spec":{"disableAllDefaultSources":true}}' --type=merge &&\
    log_ok "Config patched successfully";
  } || {
    exit_on_err 6 "Error when patching 'operatorhub.config.openshift.io/cluster' object"
  }
}

create_imagecontentsourcepolicy() {
  # Since the regular RedHat registry is not available for pulling
  #  custom IIBs, we create this object to make the cluster look 
  #  into brew registry instead
  log_info "Installing ImageContentSourcePolicy ${ITL}'brew-registry'${RST}"
  {
    envsubst < "manifests/01-ImageContentSourcePolicy.yaml" | oc apply -f - &&\
    log_ok "${BLD}ImageContentSourcePolicy${RST} has been created";
  } || {
  exit_on_err 3 "Unable to create ImageContentSourcePolicy to point brew registry"
  }
}

create_catalogsource() {
  # The catalogsource object provides an alternative source
  # to install operators, in this case, instead of using
  # the marketplace, we add operators from a custom IIB.
  log_info "Installing CatalogSource ${ITL}'iib-${QUAY_USER}'${RST}"
  {
    envsubst < "manifests/02-CatalogSource.yaml" | oc apply -f - &&\
    log_ok "${BLD}CatalogSource${RST} has been created"
    } || {
    exit_on_err 4 "Unable to create CatalogSource for IIB ${IIB_ID}"
  }
}

create_subscription() {
  # The Subscription is the object that OLM uses to install an operator
  #  from a CatalogSource
  {
    envsubst < "manifests/03-Subscription.yaml" | oc apply -f - &&\
    log_ok "${BLD}Subscription${RST} has been created"
    } || {
    exit_on_err 6 "Unable to create Subscription ${ITL}'openshift-gitops-operator'${RST}"
  }
}

###################################################

## RUN
log_info "Checking dependencies"
check_dependencies "${needed_commands[@]}" || exit_on_err 1 "Dependencies not met"

#  If the user provides $IIB_ID, the script interprets that
#  they want to install a custom (RC) image, so it will fail if
#  no $GITOPS_VERSION is provided.
#  If the user provides $GITOPS_VERSION but no $IIB_ID, the script
#  interprets that they want to install a released operator (GA) with
#  a specific version.
if [[ -z "${IIB_ID}" ]]; then
  if [[ -z "${GITOPS_VERSION}" ]]; then
    export CHANNEL="latest"
    export CATALOG_SOURCE="redhat-marketplace"
  elif [[ -n "${GITOPS_VERSION}" ]]; then
    export CHANNEL="gitops-${GITOPS_VERSION}"
    export CATALOG_SOURCE="redhat-marketplace"
  fi
elif [[ -n "${IIB_ID}" ]]; then
  if [[ -n "${GITOPS_VERSION}" ]]; then
    export CHANNEL="gitops-${GITOPS_VERSION}"
    export CATALOG_SOURCE="iib-${QUAY_USER}"
    log_info "${BBLU}IIB_ID${RST}=${YLW}${IIB_ID}${RST}"
  elif [[ -z "${GITOPS_VERSION}" ]]; then
    exit_on_err 7 "If \$IIB_ID is set, you need to provide \$GITOPS_VERSION"
  fi
fi

# ImageContentSourcePolicy and CatalogSource
if [[ -n "${IIB_ID}" ]]; then
  log_info "Installing Image Content Source Policy"
  create_imagecontentsourcepolicy
  log_info "Installing custom Catalog Source"
  create_catalogsource
fi

# Subscription
log_info "Creating subscription"
log_info "${BBLU}CHANNEL${RST}=${YLW}${CHANNEL}${RST}"
log_info "${BBLU}CATALOG SOURCE${RST}=${YLW}${CATALOG_SOURCE}${RST}"
create_subscription

log_ok "${BLD}GitOps operator installed${RST} ${BGRN}successfully${RST}"
