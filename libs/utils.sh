#!/usr/bin/env bash

LIBS_FOLDER=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
LIBS_MESSAGES="$LIBS_FOLDER/messages.sh"
SCRIPT_NAME="$(basename -- "${BASH_SOURCE[0]}")"
ENV_FILE="$LIBS_FOLDER/.${SCRIPT_NAME%.*}"

function test_check_args() { echo "${FUNCNAME[0]}"; }

function _test_check_args_with_env() { exit 0; }

function test_init_env() {
  declare -A TEST_ENV_PARAMS=( [TEST_ENV_KEY]="TEST_ENV_VALUE" )
  init_env "$ENV_FILE" "$(declare -p TEST_ENV_PARAMS)"
}

function show_message() { bash "$LIBS_MESSAGES" "${FUNCNAME[0]}" "$@"; }

function check_args() {
  FUNCTION_NAME=$1 && [[ -z "$FUNCTION_NAME" ]] && { show_message "Please provide a function name" 1; exit 1; }
  [[ ! $(type -t "$FUNCTION_NAME") == function ]] &&
    { show_message "Function with name '$FUNCTION_NAME' not exists" 1; exit 1; }
  if [ "${FUNCTION_NAME:0:1}" = "_" ]; then load_env; fi
}

function load_env() {
  if [ "$SCRIPT_NAME" = "utils.sh" ]; then
    echo "load_env"
  else
    eval "source $ENV_FILE"
  fi
}

function init_env() {
  if [ ! "$SCRIPT_NAME" = "utils.sh" ]; then
    ENV_FILE=$1 && [[ -z "$ENV_FILE" ]] && { show_message "Please provide the env file" 1; exit 1; }
  fi
  ENV_PARAMS=${2#*=} && eval "declare -A ENV_PARAMS=$ENV_PARAMS"

  # Initializing the environment file
  rm -f "$ENV_FILE"
  for ENV_PARAM in "${!ENV_PARAMS[@]}"; do
    echo "$ENV_PARAM=${ENV_PARAMS[$ENV_PARAM]}" >> "$ENV_FILE"
  done
}

check_args "$@" && "$@"
