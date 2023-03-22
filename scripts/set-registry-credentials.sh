#!/usr/bin/env bash
#
# Update OpenShift configuration with Brew registry credentials.
# Docker default auth file: ~/.docker/config.json
# Podman default auth file: ${XDG_RUNTIME_DIR}/containers/auth.json

## Import common
#  This script is intended to be called from the 
#  Makefile in the root dir, so the path is relative
#  to that root dir.
source "scripts/common.sh"

## TRAP
trap '{ trap_exit ${BASH_SOURCE} ${?}; }' EXIT SIGINT SIGTERM
trap 'trap_err ${?} ${LINENO} ${BASH_LINENO} ${BASH_COMMAND} $(printf "::%s" ${FUNCNAME[@]:-})' ERR

## Variables
needed_commands=("oc" "podman" "base64")
#TMPDIR=$(mktemp -d)
authfile=$(mktemp)
#auth_json="${DOCKER_CONFIG:-${XDG_RUNTIME_DIR}/containers/auth.json}"
#########################################

## RUN
log_info "Checking dependencies"
check_dependencies "${needed_commands[@]}" || exit_on_err 1 "Dependencies not met"

# Check or Ask for Podman credentials.
#log_info "Checking current podman credentials for Brew registry"
#{
#  podman login --get-login brew.registry.redhat.io &&\
#  log_ok "Already logged in Brew registry"
#  } || {
#  log_warn "No login information found for Brew registry"
#  log_info "Trying to login now:\n"
#  podman login brew.registry.redhat.io
#  } || {
#  exit_on_err 2 "Unable to get Brew registry credentials"
#}

## Add Brew credentials to OCP:
# 1. Get current information
log_info "Getting current login information from the cluster secret"
{
  oc get secrets pull-secret \
    -n openshift-config \
    -o template='{{index .data ".dockerconfigjson"}}' \
    | base64 -d > "${authfile}"
  } || {
  exit_on_err 2 "Unable to gather current login information from OCP cluster"
}

# 2. Get Brew registry credentials
log_info "Updating authfile with your brew credentials"
{
  podman login --authfile "${authfile}" brew.registry.redhat.io
  } || {
  exit_on_err 3 "Something went wrong when trying to get your Brew login info"
}                    

# 3. Append the key:value to the JSON file
#log_info "Appending login information into the JSON document"
#{
#  jq --arg secret "${brew_secret}" \
#    '.auths |= . + {"brew.registry.redhat.io":{"auth":$secret}}' \
#    "${oldauth}" > "${newauth}"
#  } || {
#  exit_on_err 5 "Error when updating the JSON document with the Brew login info"
#}

# 4. Update the pull-secret information in OCP
log_info "Pushing the updated information back to the secret"
{
  oc set data secret pull-secret \
    -n openshift-config \
    --from-file=.dockerconfigjson="${authfile}"
  } || {
  exit_on_err 4 "An error ocurred trying to update registry information in the cluster"
} 

log_ok "Your brew registry access token has been added to the cluster"

