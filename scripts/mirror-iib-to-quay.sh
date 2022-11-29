#!/usr/bin/env bash

## Import common
source "scripts/common.sh"

## TRAP
trap 'trap_exit ${?}' EXIT SIGINT SIGTERM
trap 'trap_err ${?} ${LINENO} ${BASH_LINENO} ${BASH_COMMAND} $(printf "::%s" ${FUNCNAME[@]:-})' ERR

log_info "Mirroring IIB ${IIB_ID} image to Quay.io"
podman pull "registry-proxy.engineering.redhat.com/rh-osbs/iib:${IIB_ID}"
podman tag "registry-proxy.engineering.redhat.com/rh-osbs/iib:${IIB_ID}" "quay.io/${QUAY_USER}/iib:${IIB_ID}"
podman push "quay.io/${QUAY_USER}/iib:${IIB_ID}"
log_ok "Image 'quay.io/${QUAY_USER}/iib:${IIB_ID}' is ready"

## TODO

