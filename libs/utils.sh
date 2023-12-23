#!/usr/bin/env bash
# @file utils.sh
# @brief A utility library.
# @description
#     The library allows you to check the settings and environment file.

LIBS_FOLDER=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
ENV_FOLDER=$( cd -- $LIBS_FOLDER/../env &> /dev/null && pwd )
LIBS_MESSAGES="$LIBS_FOLDER/messages.sh"
SCRIPT_NAME="$(basename -- "${BASH_SOURCE[0]}")"
ENV_FILE="$ENV_FOLDER/.${SCRIPT_NAME%.*}"
PARENT_COMMAND=$(ps -o args= $PPID|grep "libs"|cut -d " " -f2)
CALL_UTILS=false && [[ -z $PARENT_COMMAND ]] && CALL_UTILS=true

die() { bash "$LIBS_MESSAGES" "${FUNCNAME[0]}" "$@"; }

# @description Check if a function name exists.
#
# @arg $1 string Function name.
function check_args() {
  if ! $CALL_UTILS; then declare -f check_args ; exit 0; fi
  FUNCTION_NAME=$1 && [[ -z "$FUNCTION_NAME" ]] && { die "Please provide a function name" ; exit 1; }
  [[ ! $(type -t "$FUNCTION_NAME") == function ]] && { die "Function with name '$FUNCTION_NAME' not exists" ; exit 1; }
  if [ "${FUNCTION_NAME:0:1}" = "_" ]; then load_env; fi
}

# @description Load the environment variables with the .env file.
function load_env() {
  # shellcheck source=./utils.sh
  source "$ENV_FILE"
}

# @description Generate an environment file from an array of parameters.
#
# @arg $1 string An environment file.
# @arg $2 array An array of parameters.
function init_env() {
  if ! $CALL_UTILS; then
    ENV_FILE=$1 && [[ -z "$ENV_FILE" ]] && { die "Please provide the env file" ; exit 1; }
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

# @description Check arguments, used for unit test.
function test_check_args() { check_args "${FUNCNAME[0]}" ; echo "${FUNCNAME[0]}" ; }

# @description Check arguments with an environment file, used for unit test.
function _test_check_args_with_env() { check_args "${FUNCNAME[0]}" ; cat "$ENV_FILE" ; }

"$@"
