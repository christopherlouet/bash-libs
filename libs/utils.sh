#!/usr/bin/env bash

LIBS_FOLDER=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
LIBS_MESSAGES="$LIBS_FOLDER/messages.sh"
SCRIPT_NAME="$(basename -- "${BASH_SOURCE[0]}")"
ENV_FILE="$LIBS_FOLDER/.${SCRIPT_NAME%.*}"
PARENT_COMMAND=$(ps -o args= $PPID|grep "libs"|cut -d " " -f2)
CALL_UTILS=false && [[ -z $PARENT_COMMAND ]] && CALL_UTILS=true

function test_check_args() { check_args "${FUNCNAME[0]}" ; echo "${FUNCNAME[0]}" ; }

function _test_check_args_with_env() { check_args "${FUNCNAME[0]}" ; cat "$ENV_FILE" ; }

function show_message() { bash "$LIBS_MESSAGES" "${FUNCNAME[0]}" "$@" ; }

function check_args() {
  if ! $CALL_UTILS; then declare -f check_args ; exit 0; fi
  FUNCTION_NAME=$1 && [[ -z "$FUNCTION_NAME" ]] && { show_message "Please provide a function name" 1; exit 1; }
  [[ ! $(type -t "$FUNCTION_NAME") == function ]] &&
    { show_message "Function with name '$FUNCTION_NAME' not exists" 1; exit 1; }
  if [ "${FUNCTION_NAME:0:1}" = "_" ]; then load_env; fi
}

function load_env() {
  # shellcheck source=./utils.sh
  source "$ENV_FILE"
}

function init_env() {
  if ! $CALL_UTILS; then
    ENV_FILE=$1 && [[ -z "$ENV_FILE" ]] && { show_message "Please provide the env file" 1; exit 1; }
    ENV_PARAMS=${2#*=} && eval "declare -A ENV_PARAMS=$ENV_PARAMS"
  else
    declare -A ENV_PARAMS=( [TEST_ENV_KEY]="TEST_ENV_VALUE" )
  fi
  # Initializing the environment file
  rm -f "$ENV_FILE"
  for ENV_PARAM in "${!ENV_PARAMS[@]}"; do
    echo "$ENV_PARAM=${ENV_PARAMS[$ENV_PARAM]}" >> "$ENV_FILE"
  done
}

"$@"
