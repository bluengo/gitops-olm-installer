#!/usr/bin/env bash
#
# Mirror IIB image to make it available for OCP cluster.

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
needed_vars=("IIB_ID" "QUAY_USER")
src_registry="brew.registry.redhat.io/rh-osbs"
dst_registry="quay.io/${QUAY_USER}"

## Functions
registry_login() {
  {
    podman login --get-login "${1}" > /dev/null
  } || {
    log_warn "Credentials missing for registry ${1}"
    log_info "Trying to login now..."
    podman login "${1}"
  } || {
    exit_on_err 3 "Unable to login with podman against ${1}"
  }
}
###################################################

## RUN
log_info "Checking dependencies"
check_dependencies "${needed_commands[@]}" || exit_on_err 1 "Dependencies not met"
log_info "Checking variables"
check_variables "${needed_vars[@]}" || exit_on_err 2 "Please, provide the required variables"

log_info "Mirroring IIB ${BLD}${IIB_ID}${RST} image to Quay.io"

# 1. Pull image
log_info "Pulling image ${src_registry}/iib:${IIB_ID}..."
registry_login "${src_registry}"
{
  podman pull "${src_registry}/iib:${IIB_ID}" &&\
  log_ok "Image ${src_registry}/iib:${IIB_ID} pulled successfully"
  } || {
  exit_on_err 4 "Unable to pull image ${src_registry}/iib:${IIB_ID}"
}

# 2. Tag image
log_info "Tagging image to ${dst_registry}/iib:${IIB_ID}"
{
  podman tag "${src_registry}/iib:${IIB_ID}" "${dst_registry}/iib:${IIB_ID}" &&\
  log_ok "Successfully tagged IIB image"
  } || {
  exit_on_err 5 "Error when trying to tag image ${src_registry}/iib:${IIB_ID}"
}

# 3. Push image
log_info "Pushing ${dst_registry}/iib:${IIB_ID} to registry..."
registry_login "${dst_registry}"
{
  podman push "${dst_registry}/iib:${IIB_ID}" &&\
  log_ok "Image ${dst_registry}/iib:${IIB_ID} pushed successfully"
  } || {
  # If the system has docker credentials configured, sometimes podman
  # fails pushing the image. Login out with Docker works:
  docker logout "${dst_registry}" &&\
  registry_login "${dst_registry}" &&\
  podman push "${dst_registry}/iib:${IIB_ID}"
  } || {
  exit_on_err 6 "Unable to push image quay.io/${QUAY_USER}/iib:${IIB_ID}"
}

log_ok "The IIB ${BLD}${dst_registry}/iib:${IIB_ID}${RST} is ready to be used"

