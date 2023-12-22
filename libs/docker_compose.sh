#!/usr/bin/env bash

LIBS_FOLDER=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
CONFIG_FOLDER=$( cd -- $LIBS_FOLDER/../config &> /dev/null && pwd )
ENV_FOLDER=$( cd -- $LIBS_FOLDER/../env &> /dev/null && pwd )
LIBS_MESSAGES="$LIBS_FOLDER/messages.sh"
LIBS_UTILS="$LIBS_FOLDER/utils.sh"
SCRIPT_NAME="$(basename -- "${BASH_SOURCE[0]}")"
ENV_FILE="$ENV_FOLDER/.${SCRIPT_NAME%.*}"

main() { eval "$(bash "$LIBS_UTILS" "check_args" "$@") ; check_env ; check_args $*" ; "$@"; }
show_message() { bash "$LIBS_MESSAGES" "${FUNCNAME[0]}" "$@"; }
confirm_message() { bash "$LIBS_MESSAGES" "${FUNCNAME[0]}" "$@"; }
die() { bash "$LIBS_MESSAGES" "${FUNCNAME[0]}" "$@"; }
init_env() { bash "$LIBS_UTILS" "${FUNCNAME[0]}" "$@"; }

function load_env() {
  if [ ! -f "$ENV_FILE" ]; then
    die "Please initialize the environment file with the command '$SCRIPT_NAME init project_name'" 1; exit 1;
  fi
  # shellcheck source=./docker_compose.env
  source "$ENV_FILE"
}

function check_env() {
  if ! docker compose version 2>&1 | grep "Docker Compose version" 2> /dev/null > /dev/null ; then
    die "docker compose could not be found" ; exit 1
  fi
}

# Initialize environment variables for a docker-compose project.
#
# $1 - Project name.
# $2 - A project folder (Default config/project_name).
# $3 - A docker compose file (Default docker-compose.yml).
# $4 - A docker compose profile (Optional).
# $5 - A docker compose environment file (Optional).
# $6 - A reference service to check the status (Optional).
#
# Examples:
# ./libs/docker_compose.sh init "project_name"  # Initialize the project
#
# Returns nothing.
init() {
  # Project name
  local DC_PROJECT_NAME=$1
  # Project folder
  local DC_FOLDER=$CONFIG_FOLDER/${2:-$(echo "$DC_PROJECT_NAME"|rev|cut -d"/" -f1|rev)}
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

# Build a docker compose command.
#
# $2 - Command to launch.
# $2 - Project folder (Default config/docker_compose).
# $3 - Docker compose file name (Default docker-compose.yml).
# $4 - Options to place.
#
# Returns the generated command.
dc_build_docker_compose() {
  local dc_command=$1
  local dc_folder=${2:-$CONFIG_FOLDER/docker_compose}
  local dc_file=${3:-docker-compose.yml}
  # shellcheck disable=SC2124
  local dc_options="${@:4: $#-1}"
  [[ -z "$dc_command" ]] && die "Please provide a command" && return 1
  docker compose $dc_command 2>&1|tail -n1|grep "unknown docker command" > /dev/null
  # shellcheck disable=SC2181
  [[ $? -eq 0 ]] && die "Unknown docker command: $dc_command" && return 1
  echo "docker compose -f $dc_folder/$dc_file $dc_command $dc_options"
}

# Generate options to pass in a docker compose command.
#
# $1 - Show the options (Default false).
# $2 - Options to pass.
#
# Returns the generated options.
_dc_build_options() {
  local show=${1:-0}
  # shellcheck disable=SC2124
  dc_build_options="${@:2: $#-1}"
  [[ -n $DC_PROFILE ]] && dc_build_options="$dc_build_options --profile $DC_PROFILE"
  [[ -n $DC_ENV_FILE ]] && dc_build_options="$dc_build_options --env-file $DC_FOLDER/$DC_ENV_FILE"
  [[ $show -eq 1 ]] && echo "$dc_build_options"
}

# Execute or show a docker compose command.
#
# $1 - Command to execute.
# $2 - Show generated command (Default true).
# $3 - Project folder (Default current directory).
# $4 - Docker compose file name (Default docker-compose.yml).
# $5 - Options to pass.
#
# Returns nothing or the generated command.
dc_exec_command() {
  local dc_command=$1
  local show=${2:-1}
  local dc_folder=${3:-$CONFIG_FOLDER/docker_compose}
  local dc_file=${4:-docker-compose.yml}
  # shellcheck disable=SC2124
  local dc_options="${@:5: $#-1}"
  local dc_build_docker_compose
  [[ -z $dc_command ]] && die "Please provide a docker compose command" && return 1
  [[ ! -f $dc_folder/$dc_file ]] && die "Please provide a docker compose file" && return 1
  dc_build_docker_compose=$(dc_build_docker_compose $dc_command $dc_folder $dc_file $dc_options)
  [[ $? -eq 1 ]] && return 1
  [[ $show -eq 1 ]] && echo $dc_build_docker_compose
  [[ $show -eq 0 ]] && eval $dc_build_docker_compose
  return 0
}

# Execute or show a docker compose command with environment file.
#
# $1 - Command to execute
# $2 - Show generated command (Default true).
# $3 - Options to pass.
#
# Returns nothing or the generated command.
_dc_exec_command() {
  local dc_command=$1
  local show=${2:-1}
  # shellcheck disable=SC2124
  local dc_options="${@:3: $#-1}"
  [[ -z $dc_command ]] && die "Please provide a docker compose command" && return 1
  _dc_build_options 0 $dc_options
  dc_exec_command $dc_command $show $DC_FOLDER $DC_FILE $dc_build_options
}

# Show the service status.
#
# $1 - Project folder (Default current directory).
# $2 - Docker compose file name (Default docker-compose.yml).
# $3 - Service name.
#
# Returns the service status.
dc_status() {
  local dc_folder=${1:-$LIBS_FOLDER/..}
  local dc_file=${2:-docker-compose.yml}
  local service_name=$3
  local result
  [[ ! -f $dc_folder/$dc_file ]] && die "Please provide a docker compose file" && return 1
  [[ -z $service_name ]] && die "Please provide a docker compose service name" && return 1
  result=$(docker compose -f "$dc_folder/$dc_file" ps -q $service_name 2>&1)
  [[ $? -eq 1 ]] && show_message "$result" 1 && return 1
  [[ -z $result ]] && die "Service with name $service_name is not created" && return 1
  docker inspect --format "{{.State.Status}}" "$result"
}

# Show the service status with environment file.
#
# Returns the service status.
_dc_status() {
  dc_status $DC_FOLDER $DC_FILE $DC_SERVICE_REF
}

# Check initializer status
#_initializer_status() {
#  local initializer_status
#  # shellcheck disable=SC2046
#  initializer_status=$(docker ps -q --no-trunc | \
#          grep $(docker-compose --log-level ERROR -f "$DD_FOLDER/docker-compose.yml" ps -q initializer))
#  if [ -z "$initializer_status" ]; then
#    echo "stop"
#  else
#    echo "up"
#  fi
#}

dc_waiting_start() {
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
