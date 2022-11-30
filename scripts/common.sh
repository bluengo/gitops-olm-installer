#!/usr/bin/env bash

## COLOR and FORMATTING
declare -r RED='\e[91m' # Red color
declare -r GRN='\e[92m' # Green color
declare -r BLU='\e[96m' # Blue color
declare -r YLW='\e[93m' # Yellow color
declare -r BLD='\e[1m'  # Bold
declare -r ITL='\e[3m'  # Italic
declare -r RST='\e[0m'  # Reset format

## LOGGING.
timestamp()
{
  date --utc '+%Y-%m-%d %H:%M:%S UTC - '
}

# Create a temporary log file if not set.
LOGFILE=${LOGFILE:-$(mktemp)}

log_ok()
{
  # Prints the timestamp with a green [OK] followed by the message ($1)
  echo -e "$(timestamp)${GRN}[OK]:${RST} ${1}" | tee -a "${LOGFILE}"
}

log_info() {
  # Prints the timestamp with [INFO] followed by the message ($1)
  echo -e "$(timestamp)[INFO]: ${1}" | tee -a "${LOGFILE}"
}

log_warn()
{
  # Prints the timestamp with a yellow [WARNING] followed by the message ($1)
  echo -e "$(timestamp)${YLW}[WARNING]:${RST} ${1}" | tee -a "${LOGFILE}"
}

log_err()
{
  # Prints the timestamp with a red [ERROR] followed by the message ($1)
  echo -e "$(timestamp)${RED}[ERROR]:${RST} ${1}" | tee -a "${LOGFILE}"
}

exit_on_err()
{
  # Prints the message ($2) as an error and exits with status ($1)
  log_err "${2}"
  echo -e "$(timestamp)${YLW}[EXIT]: Stopping execution now...${RST}"
  exit "${1}"
}

## Check required parameters (ENV VARS).
check_variables ()
{
  for var in "${@}"; do
    if [[ -z "${var}" ]]; then
      log_err "Missing var ${var}"
      return 1
    fi
  done
  return 0
}

## Check dependencies (linux packages).
check_dependencies()
{
  for dep in "${@}"; do
    {
    command -v "${dep}" &>/dev/null
    } || {
      log_err "Missing command ${dep}"
      return 1
    }
  done
  return 0
}

## TRAP for graceful exit.
trap_exit()
{
  log_info "Exited '${1}' with status ${2}"
  rm -rf "${TMPDIR}"
}

## TRAP for exit on error.
trap_err()
{
  local exitstat="${1}"       # $?
  local line="${2}"           # $LINENO
  local linecallfunc="${3}"   # $BASH_LINENO
  local command="${4}"        # $BASH_COMMAND
  local funcstack="${5}"      # $FUNCNAME

  log_err "'${command}' failed at line ${line} - exited with status: ${exitstat}"

  if [[ "${funcstack}" != "::" ]]; then
    if [[ "${linecallfunc}" != "" ]]; then
      local called="Called at line ${linecallfunc}"
    fi
    log_err "DEBUG: Error in ${funcstack}. ${called}"
    [[ "${linecallfunc}" != "0" ]] && log_err "$(sed "${linecallfunc}!d" "${0}")"
  fi
}

