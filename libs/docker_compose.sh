#!/usr/bin/env bash
# @file docker_compose.sh
# @brief A library for running docker compose commands with an environment file.
# @description
#     The library allows you to launch a docker compose command by retrieving the parameters in an environment file.

LIBS_FOLDER=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
CONFIG_FOLDER=$( cd -- $LIBS_FOLDER/../config &> /dev/null && pwd )
ENV_FOLDER=$( cd -- $LIBS_FOLDER/../env &> /dev/null && pwd )
LIBS_MESSAGES="$LIBS_FOLDER/messages.sh"
LIBS_UTILS="$LIBS_FOLDER/utils.sh"
SCRIPT_NAME="$(basename -- "${BASH_SOURCE[0]}")"
ENV_FILE="$ENV_FOLDER/.${SCRIPT_NAME%.*}"
DC_DEBUG=0

main() { eval "$(bash "$LIBS_UTILS" "check_args" "$@") ; check_env ; check_args $*" ; "$@"; }
show_message() { bash "$LIBS_MESSAGES" "${FUNCNAME[0]}" "$@"; }
confirm_message() { bash "$LIBS_MESSAGES" "${FUNCNAME[0]}" "$@"; }
die() { bash "$LIBS_MESSAGES" "${FUNCNAME[0]}" "$@"; }
init_env() { bash "$LIBS_UTILS" "${FUNCNAME[0]}" "$@"; }

# @description Load the environment variables with the .env file.
function load_env() {
  if [ ! -f "$ENV_FILE" ]; then
    die "Please initialize the environment file with the command '$SCRIPT_NAME init project_name'" 1; exit 1;
  fi
  # shellcheck source=./docker_compose.env
  source "$ENV_FILE"
}

# @description Check if docker compose is installed,
function check_env() {
  if ! docker compose version 2>&1 | grep "Docker Compose version" 2> /dev/null > /dev/null ; then
    die "docker compose could not be found" ; exit 1
  fi
}

# @description Initialize environment variables for a docker compose project.
#
# @arg $1 string Project name.
# @arg $2 string A project folder (Default config/docker_compose).
# @arg $3 string A docker compose file (Default docker-compose.yml).
# @arg $4 string A docker compose profile (Optional).
# @arg $5 string A docker compose environment file (Optional).
# @arg $6 string A reference service to check the status (Optional).
#
# @example
# ./libs/docker_compose.sh init "project_name"
init() {
  # Project name
  local DC_PROJECT_NAME=$1
  # Project folder
  local DC_FOLDER=${2:-$CONFIG_FOLDER/$(echo "$DC_PROJECT_NAME"|rev|cut -d"/" -f1|rev)}
  # Docker-compose file
  local DC_FILE=${3:-docker-compose.yml}
  local DC_PROFILE=$4
  local DC_ENV_FILE=$5
  local DC_SERVICE_REF=$6
  # Initializing environment variables
  declare -A ENV_PARAMS=(
    [DC_PROJECT_NAME]=$DC_PROJECT_NAME
    [DC_FOLDER]=$DC_FOLDER
    [DC_FILE]=$DC_FILE
    [DC_PROFILE]=$DC_PROFILE
    [DC_ENV_FILE]=$DC_ENV_FILE
    [DC_SERVICE_REF]=$DC_SERVICE_REF
  )
  init_env "$ENV_FILE" "$(declare -p ENV_PARAMS)"
}

# @description Build a docker compose command.
#
# @arg $1 string Docker compose file path.
# @arg $2 string Command to launch.
# @arg $3 array Options to place.
#
# @example
# ./libs/docker_compose.sh dc_build_docker_compose config/docker_compose/docker-compose.yml start --env-file .env.test
dc_build_docker_compose() {
  local dc_path_file=$1
  local dc_command=$2
  # shellcheck disable=SC2124
  local dc_options="${@:3: $#-1}"
  [[ ! -f $dc_path_file ]] && die "Please provide a docker compose file" && return 1
  [[ -z "$dc_command" ]] && die "Please provide a command" && return 1
  docker compose $dc_command 2>&1|tail -n1|grep "unknown docker command" > /dev/null
  # shellcheck disable=SC2181
  [[ $? -eq 0 ]] && die "Unknown docker command: $dc_command" && return 1
  if [ -z "$dc_options" ]; then
    echo "docker compose -f $dc_path_file $dc_command"
  else
    echo "docker compose -f $dc_path_file $dc_options $dc_command"
  fi
}

# @description Generate options to pass in a docker compose command with **environment file**.
#
# @arg $1 boolean Show the options (Default false).
# @arg $2 array Options to pass.
#
# @example
# ./libs/docker_compose.sh _dc_build_options 1
_dc_build_options() {
  local show=${1:-0}
  # shellcheck disable=SC2124
  dc_build_options="${@:2: $#-1}"
  [[ -n $DC_PROFILE ]] && dc_build_options="$dc_build_options --profile $DC_PROFILE"
  [[ -n $DC_ENV_FILE ]] && dc_build_options="$dc_build_options --env-file $CONFIG_FOLDER/$DC_FOLDER/$DC_ENV_FILE"
  [[ $show -eq 1 ]] && echo "$dc_build_options"
}

# @description Execute or show a docker compose command.
#
# @arg $1 string Docker compose file path.
# @arg $2 boolean Show generated command (Default true).
# @arg $3 string Command to execute.
# @arg $4 array Options to pass.
#
# @example
# ./libs/docker_compose.sh dc_exec_command config/docker_compose/docker-compose.yml 1 start --env-file .env.test
dc_exec_command() {
  local dc_path_file=$1
  local show=${2:-1}
  local dc_command=$3
  # shellcheck disable=SC2124
  local dc_options="${@:4: $#-1}"
  local dc_build_docker_compose

  # Debug dc_exec_command
  if [ $DC_DEBUG -eq 1 ]; then
    echo "dc_path_file: $dc_path_file"
    echo "show: $show"
    echo "dc_command: $dc_command"
    echo "dc_options: $dc_options"
  fi

  [[ ! -f $dc_path_file ]] && die "Please provide a docker compose file" && return 1
  [[ -z $dc_command ]] && die "Please provide a docker compose command" && return 1
  dc_build_docker_compose=$(dc_build_docker_compose "$dc_path_file" $dc_command $dc_options)
  [[ $? -eq 1 ]] && return 1
  [[ $show -eq 1 ]] && echo $dc_build_docker_compose
  [[ $show -eq 0 ]] && eval $dc_build_docker_compose
  return 0
}

# @description Execute or show a docker compose command with **environment file**.
#
# @arg $1 boolean Show generated command (Default true).
# @arg $2 string Command to execute
# @arg $3 array Options to pass.
#
# @example
# ./libs/docker_compose.sh _dc_exec_command 1 start
_dc_exec_command() {
  local show=${1:-1}
  local dc_command=$2
  # shellcheck disable=SC2124
  local dc_options="${@:3: $#-1}"
  [[ -z $dc_command ]] && die "Please provide a docker compose command" && return 1
  _dc_build_options 0 $dc_options
  dc_exec_command $CONFIG_FOLDER/$DC_FOLDER/$DC_FILE $show $dc_command $dc_build_options
}

# @description Show the service status.
#
# @arg $1 string Docker compose file path.
# @arg $2 string Service name.
#
# @example
# ./libs/docker_compose.sh dc_status config/docker_compose/docker-compose.yml dc_test1
dc_status() {
  local dc_path_file=$1
  local service_name=$2
  local result
  [[ ! -f $dc_path_file ]] && die "Please provide a docker compose file" && return 1
  [[ -z $service_name ]] && die "Please provide a docker compose service name" && return 1
  result=$(docker compose -f "$dc_path_file" ps -q $service_name 2>&1)
  [[ $? -eq 1 ]] && show_message "$result" 1 && return 1
  [[ -z $result ]] && die "Service with name $service_name is not created" && return 1
  docker inspect --format "{{.State.Status}}" "$result"
}

# @description Show the service status with **environment file**.
#
# @example
# ./libs/docker_compose.sh _dc_status
_dc_status() {
  dc_status $CONFIG_FOLDER/$DC_FOLDER/$DC_FILE $DC_SERVICE_REF
}

# @description Show a prompt during container startup with **environment file**.
#
# @example
# ./libs/docker_compose.sh _dc_waiting_start
_dc_waiting_start() {
  i=0
  spin='-\|/'
  start=$(date +%s)
  status="up"
  while [ "$status" = "up" ]; do
    i=$(( (i+1) %4 ))
    printf "\r\033[0;32mWaiting application start... %s" ${spin:$i:1}
    sleep 0.2
    status=$(_dc_status)
  done
  cur=$(date +%s)
  runtime=$(( cur-start ))
  printf " done (%ss)\033[0m\n" $runtime
}

main "$@"
