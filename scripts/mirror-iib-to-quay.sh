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
needed_commands=("podman")
###################################################

## RUN
log_info "Checking dependencies"
check_dependencies "${needed_commands[@]}" || exit_on_err 1 "Dependencies not met"

log_info "Mirroring IIB ${IIB_ID} image to Quay.io"
podman pull "registry-proxy.engineering.redhat.com/rh-osbs/iib:${IIB_ID}"
podman tag "registry-proxy.engineering.redhat.com/rh-osbs/iib:${IIB_ID}" "quay.io/${QUAY_USER}/iib:${IIB_ID}"
podman push "quay.io/${QUAY_USER}/iib:${IIB_ID}"
log_ok "Image 'quay.io/${QUAY_USER}/iib:${IIB_ID}' is ready"

## TODO

