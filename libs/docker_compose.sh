#!/usr/bin/env bash

LIBS_FOLDER=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
LIBS_MESSAGES="$LIBS_FOLDER/messages.sh"
LIBS_UTILS="$LIBS_FOLDER/utils.sh"
SCRIPT_NAME="$(basename -- "${BASH_SOURCE[0]}")"
ENV_FILE="$LIBS_FOLDER/.${SCRIPT_NAME%.*}"

main() { eval "$(bash "$LIBS_UTILS" "check_args" "$@") ; check_args $*" ; check_env; "$@"; }
init_env() { bash "$LIBS_UTILS" "${FUNCNAME[0]}" "$@"; }

function load_env() {
  if [ ! -f "$ENV_FILE" ]; then
    show_message "Please initialize the environment file with the command '$SCRIPT_NAME init project_name'" 1; exit 1;
  fi
  # shellcheck source=./docker_compose.env
  source "$ENV_FILE"
}

function check_env() {
  if !  docker compose version | grep "Docker Compose version" &> /dev/null; then
      show_message "docker compose could not be found" 1; exit 1
  fi
}

# Message functions
show_message() { bash "$LIBS_MESSAGES" "${FUNCNAME[0]}" "$@"; }
confirm_message() { bash "$LIBS_MESSAGES" "${FUNCNAME[0]}" "$@"; }

# Initialize environment variables for a docker-compose project.
#
# $1 - Project name.
# $2 - A project folder (Default current directory).
# $3 - A docker compose file (Default docker-compose.yml).
# $4 - A docker compose profile (Optional).
# $5 - A docker compose environment file (Optional).
# $6 - A reference service to check the status (Optional).
#
# Examples:
# ./libs/docker_compose.sh init "project_name"  # Initialize the project in the parent folder
#
# Returns nothing.
init() {
  # Project name
  DC_PROJECT_NAME=$1
  # Project folder
  DC_FOLDER=${2:-$LIBS_FOLDER/../$(echo "$DC_PROJECT_NAME"|rev|cut -d"/" -f1|rev)}
  # Docker-compose file
  DC_FILE=${3:-docker-compose.yml}
  DC_PROFILE=$4
  DC_ENV_FILE=$5
  DC_SERVICE_REF=$6
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
# $1 - Project folder (Default current directory).
# $2 - Docker compose file name (Default docker-compose.yml).
# $3 - Command to launch.
# $4 - Options to place.
#
# Returns the generated command.
dc_build_docker_compose() {
  dc_folder=${1:-$LIBS_FOLDER/..}
  dc_file=${2:-docker-compose.yml}
  dc_command=$3
  # shellcheck disable=SC2124
  dc_options="${@:4: $#-1}"
  [[ -z "$dc_command" ]] && show_message "Please provide a command" 1 && return 1
  echo "docker compose -f $dc_folder/$dc_file $dc_command $dc_options"
}

# Generate options to pass in a docker compose command.
#
# $1 - Display a message (Default false).
# $2 - Options to pass.
#
# Returns the generated options.
_dc_build_options() {
  dc_build_options_show=${1:-0}
  dc_build_options=$2
  [[ -n $DC_PROFILE ]] && dc_build_options="$dc_build_options --profile $DC_PROFILE"
  [[ -n $DC_ENV_FILE ]] && dc_build_options="$dc_build_options --env-file $DC_ENV_FILE"
  [[ $dc_build_options_show -eq 1 ]] && show_message "$dc_build_options"
}

# Execute or show a docker compose command.
#
# $1 - Command to execute.
# $2 - Project folder (Default current directory).
# $3 - Docker compose file name (Default docker-compose.yml).
# $4 - Show generated command (Default true).
# $5 - Options to pass.
#
# Returns nothing or the generated command.
dc_build_command() {
  dc_command=$1
  dc_folder=${2:-$LIBS_FOLDER/..}
  dc_file=${3:-docker-compose.yml}
  dc_build_cmd_show=${4:-1}
  # shellcheck disable=SC2124
  dc_options="${@:5: $#-1}"
  [[ -z $dc_command ]] && show_message "Please provide a docker compose command" 1 && return 1
  [[ ! -f $dc_folder/$dc_file ]] && show_message "Please provide a docker compose file" 1 && return 1
  build_docker_compose=$(dc_build_docker_compose $dc_folder $dc_file $dc_options $dc_command)
  [[ $dc_build_cmd_show -eq 1 ]] && echo $build_docker_compose
  [[ $dc_build_cmd_show -eq 0 ]] && eval $build_docker_compose
  return 0
}

# Execute a docker compose build.
#
# $1 - Project folder (Default current directory).
# $2 - Docker compose file name (Default docker-compose.yml).
# $3 - Show generated command (Default true).
# $4 - Options to pass.
#
# Returns nothing or the generated command.
build() {
  dc_build_command "build" "$@"
}

# Execute a docker compose build with environment file.
#
# $1 - Show generated command (Default true).
# $2 - Options to pass.
#
# Returns nothing or the generated command.
_build() {
  _dc_build_options 0 $2
  build $DC_FOLDER $DC_FILE ${1:-1} $dc_build_options
}

# Execute a docker compose down.
#
# $1 - Project folder (Default current directory).
# $2 - Docker compose file name (Default docker-compose.yml).
# $3 - Show generated command (Default true).
# $4 - Options to pass.
#
# Returns nothing or the generated command.
down() {
  dc_build_command "down" "$@"
}

# Execute a docker compose down with environment file.
#
# $1 - Show generated command (Default true).
# $2 - Options to pass.
#
# Returns nothing or the generated command.
_down() {
  _dc_build_options 0 $2
  down $DC_FOLDER $DC_FILE ${1:-1} $dc_build_options
}

# Execute a docker compose restart.
#
# $1 - Project folder (Default current directory).
# $2 - Docker compose file name (Default docker-compose.yml).
# $3 - Show generated command (Default true).
# $4 - Options to pass.
#
# Returns nothing or the generated command.
restart() {
  dc_build_command "restart" "$@"
}

# Execute a docker compose restart with environment file.
#
# $1 - Show generated command (Default true).
# $2 - Options to pass.
#
# Returns nothing or the generated command.
_restart() {
  _dc_build_options 0 $2
  restart $DC_FOLDER $DC_FILE ${1:-1} $dc_build_options
}

# Execute a docker compose stop.
#
# $1 - Project folder (Default current directory).
# $2 - Docker compose file name (Default docker-compose.yml).
# $3 - Show generated command (Default true).
# $4 - Options to pass.
#
# Returns nothing or the generated command.
stop() {
  dc_build_command "stop" "$@"
}

# Execute a docker compose stop with environment file.
#
# $1 - Show generated command (Default true).
# $2 - Options to pass.
#
# Returns nothing or the generated command.
_stop() {
  _dc_build_options 0 $2
  stop $DC_FOLDER $DC_FILE ${1:-1} $dc_build_options
}

# Execute a docker compose up.
#
# $1 - Project folder (Default current directory).
# $2 - Docker compose file name (Default docker-compose.yml).
# $3 - Show generated command (Default true).
# $4 - Options to pass.
#
# Returns nothing or the generated command.
up() {
  dc_build_command "up -d" "$@"
}

# Execute a docker compose up with environment file.
#
# $1 - Show generated command (Default true).
# $2 - Options to pass.
#
# Returns nothing or the generated command.
_up() {
  _dc_build_options 0 $2
  up $DC_FOLDER $DC_FILE ${1:-1} $dc_build_options
}

# Show the service status.
#
# $1 - Project folder (Default current directory).
# $2 - Docker compose file name (Default docker-compose.yml).
# $3 - Service name.
#
# Returns the service status.
status() {
  dc_folder=${1:-$LIBS_FOLDER/..}
  dc_file=${2:-docker-compose.yml}
  service_name=$3
  [[ ! -f $dc_folder/$dc_file ]] && show_message "Please provide a docker compose file" 1 && return 1
  [[ -z $service_name ]] && show_message "Please provide a docker compose service name" 1 && return 1
  result=$(docker compose -f "$dc_folder/$dc_file" ps -q $service_name 2>&1)
  [[ $? -eq 1 ]] && show_message "$result" 1 && return 1
  [[ -z $result ]] && show_message "Service with name $service_name is not created" 1 && return 1
  docker inspect --format "{{.State.Status}}" "$result"
}

# Show the service status with environment file.
#
# Returns the service status.
_status() {
  status $DC_FOLDER $DC_FILE $DC_SERVICE_REF
}

main "$@"
