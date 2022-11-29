#!/usr/bin/env bash

## Import common
source "scripts/common.sh"

## TRAP
trap 'trap_exit ${?}' EXIT SIGINT SIGTERM
trap 'trap_err ${?} ${LINENO} ${BASH_LINENO} ${BASH_COMMAND} $(printf "::%s" ${FUNCNAME[@]:-})' ERR

## Variables
needed_commands=("oc" "podman" "jq" "tr")

## Functions
add_brew_registry_credentials ()
{
  local oldauth
  local newauth
  local brew_secret
  oldauth=$(mktemp)
  newauth=$(mktemp)

  # Get current information
  log_info "Getting current login information from the cluster secret"
  oc get secrets pull-secret \
    -n openshift-config \
    -o template='{{index .data ".dockerconfigjson"}}' \
    | base64 -d > "${oldauth}"

  # Get Brew registry credentials
  log_info "Copying brew credentials from your config.json file"
  brew_secret=$(jq '.auths."brew.registry.redhat.io".auth' \
                      "${HOME}/.docker/config.json" \
                      | tr -d '"')

  # Append the key:value to the JSON file
  log_info "Appending login information into the JSON document"
  jq --arg secret "${brew_secret}" \
    '.auths |= . + {"brew.registry.redhat.io":{"auth":$secret}}' \
    "${oldauth}" > "${newauth}"

  # Update the pull-secret information in OCP
  log_info "Pushing the updated information back to the secret"
  oc set data secret pull-secret \
    -n openshift-config \
    --from-file=.dockerconfigjson="${newauth}"

  # Cleanup
  rm -f "${oldauth}" "${newauth}"
}

## RUN
log_info "Checking dependencies"
check_dependencies "${needed_commands[@]}" || exit_on_err 1 "Dependencies not met"

# Check or Ask for Podman credentials.
{
  podman login --get-login brew.registry.redhat.io \
  && log_ok "Already logged in Brew registry"
} || {
  log_warn "No login information found for Brew registry"
  log_info "Trying to login now:\n"
  podman login brew.registry.redhat.io
} || {
  exit_on_err 2 "Unable to get Brew registry credentials"
}

# Add Brew credentials to OCP
{
  add_brew_registry_credentials \
  && log_ok "Your brew registry access token has been added to the cluster"
} || {
  exit_on_err 3 "An error has ocurred trying to update registry information in the cluster"
}

