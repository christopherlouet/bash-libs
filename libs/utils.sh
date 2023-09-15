#!/usr/bin/env bash

CURRENT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
LIB_MESSAGES="$CURRENT_DIR/messages.sh"

show_message() { bash "$LIB_MESSAGES" "${FUNCNAME[0]}" "$@"; }

function init_env() {
  ENV_FILE=$1 && [[ -z "$ENV_FILE" ]] && { show_message "Please provide the env file" 1; exit $?; }
  ENV_PARAMS=${2#*=} && eval "declare -A ENV_PARAMS=$ENV_PARAMS"
  # Initializing the environment file
  cp /dev/null "$ENV_FILE"
  for ENV_PARAM in "${!ENV_PARAMS[@]}"; do
    echo "$ENV_PARAM=${ENV_PARAMS[$ENV_PARAM]}" >> "$ENV_FILE"
  done
}

"$@"
