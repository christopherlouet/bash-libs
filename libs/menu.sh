#!/usr/bin/env bash
# @file menu.sh
# @brief A library for manage a help menu with an environment file.
# @description
#     The library allows you to display a help menu by retrieving the parameters from a yaml configuration file.

LIBS_FOLDER=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
CONFIG_FOLDER=$( cd -- $LIBS_FOLDER/../config &> /dev/null && pwd )
ENV_FOLDER=$( cd -- $LIBS_FOLDER/../env &> /dev/null && pwd )
LIBS_MESSAGES="$LIBS_FOLDER/messages.sh"
LIBS_UTILS="$LIBS_FOLDER/utils.sh"
SCRIPT_NAME="$(basename -- "${BASH_SOURCE[0]}")"
ENV_FILE="$ENV_FOLDER/.${SCRIPT_NAME%.*}"
MENU_DEBUG=0

main() { eval "$(bash "$LIBS_UTILS" "check_args" "$@") ; check_env ; check_args $*" ; "$@"; }
show_message() { bash "$LIBS_MESSAGES" "${FUNCNAME[0]}" "$@"; }
confirm_message() { bash "$LIBS_MESSAGES" "${FUNCNAME[0]}" "$@"; }
die() { bash "$LIBS_MESSAGES" "${FUNCNAME[0]}" "$@"; }
init_env() { bash "$LIBS_UTILS" "${FUNCNAME[0]}" "$@"; }
yaml_parse() { bash "$LIBS_UTILS" "${FUNCNAME[0]}" "$@"; }

# @description Load the environment variables with the .env file.
function load_env() {
  if [ ! -f "$ENV_FILE" ]; then
    die "Please initialize the environment file with the command '$SCRIPT_NAME init project_name'" ; exit 1;
  fi
  # shellcheck source=./docker_compose.env
  source "$ENV_FILE"
}

# @description Check if yq is installed, and install it if necessary.
function check_env() {
  if ! command -v yq 2> /dev/null > /dev/null ; then
      jq_install=$(confirm_message "yq not available, do you want to install the latest version? [Y/n] " "y")
      jq_download="https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64"
      if [ "$jq_install" == "y" ]; then
        if ! command -v wget 2> /dev/null > /dev/null ; then
          wget_install=$(confirm_message "wget not available, do you want to install the latest version? [Y/n] " "y")
          if [ "$wget_install" == "y" ]; then
            sudo apt install wget
          else die "Unable to continue" ; exit 1 ; fi
        fi
        sudo wget $jq_download -O /usr/bin/yq -q --show-progress > /dev/null && sudo chmod +x /usr/bin/yq
      else
        die "Unable to continue" && exit 1
      fi
  fi
}

# @description Initialize environment variables for a menu project.
#
# @arg $1 string Project name. (default **menu**).
# @arg $2 string Project folder (default **config/menu**).
# @arg $3 string Configuration file (default **menu.yml**).
#
# @example
# ./libs/menu.sh init "project_name"  # Initialize the project
init() {
  # Project name
  MENU_PROJECT_NAME=${1:-menu}
  # Project folder
  MENU_FOLDER=${2:-$(echo "$MENU_PROJECT_NAME"|rev|cut -d"/" -f1|rev)}
  # Menu config file
  MENU_FILE=${3:-menu.yml}
  # Initializing environment variables
  declare -A ENV_PARAMS=(
    [MENU_PROJECT_NAME]=$MENU_PROJECT_NAME
    [MENU_FOLDER]=$MENU_FOLDER
    [MENU_FILE]=$MENU_FILE
  )
  init_env "$ENV_FILE" "$(declare -p ENV_PARAMS)"
}

# @description Check if the entry exists in the configuration file.
#
# @arg $1 string Configuration file path.
# @arg $2 array Options passed to script.
check_menu_entries() {
  local menu_path_file="$1"
  # shellcheck disable=SC2124
  local menu_opts=${@:2: $#-1}
  local opts_regex=""

  [[ ! -f $menu_path_file ]] && die "Please provide a menu configuration file" && return 1

  menu_name=$(yq 'keys | .[] | select(. == "name")' $menu_path_file)
  [[ -z $menu_name ]] && die "Entry .name does not exist in $menu_path_file" && return 1

  if [[ -n $menu_opts ]]; then
    for menu_opt in $menu_opts; do
      opts_regex+=".opts"
      yq "$opts_regex | keys" $menu_path_file &> /dev/null
      [[ $? -eq 1 ]] && die "Option $menu_opts does not exist" && return 1
      opts_regex+=" .$menu_opt "
      yq "$opts_regex | keys" $menu_path_file &> /dev/null
      [[ $? -eq 1 ]] && die "Option $menu_opts does not exist" && return 1
    done
  fi

  return 0
}

# @description Build the command with the required options.
#
# @arg $1 string Configuration file path.
# @arg $2 boolean Show the options (default **false**).
# @arg $3 array Options passed to script.
build_mandatory_opts() {
  local menu_path_file=$1
  local show=${2:-0}
  # shellcheck disable=SC2124
  local opts=${@:3: $#-1}
  local mandatory_opts=""
  local prefix=""

  [[ ! -f $menu_path_file ]] && die "Please provide a menu configuration file" && return 1

  # Build the mandatory options
  for opt in $opts; do
    optional=$(yq "$opts_regex .opts .$opt .optional" $menu_path_file)
    if ! [ "$optional" = "true" ]; then
      prefix=$(yq "$opts_regex .opts .$opt .prefix" $menu_path_file)
      if [ "$prefix" = "true" ]; then
        mandatory_opts+="--$opt "
      else
        mandatory_opts+="$opt "
      fi
    fi
  done

  # Generate the command to display
  if [[ -n $mandatory_opts ]]; then
    cmd_options+="["
    for opt in $mandatory_opts; do
      cmd_options+="$opt|"
    done
    cmd_options="${cmd_options::-1}] "
  fi

  [[ $MENU_DEBUG -eq 1 ]] && echo "mandatory_opts: $mandatory_opts"
  [[ $show -eq 1 ]] && echo "$cmd_options"

  return 0
}

# @description Build the command with the optional options.
#
# @arg $1 string Configuration file path.
# @arg $2 boolean Show the options (default **false**).
# @arg $3 array Options passed to script.
build_optional_opts() {
  local menu_path_file=$1
  local show=${2:-0}
  # shellcheck disable=SC2124
  local opts=${@:3: $#-1}
  local optional_opts=""
  local optional=""

  [[ ! -f $menu_path_file ]] && die "Please provide a menu configuration file" && return 1

  # Build the options
  for opt in $opts; do
    optional=$(yq "$opts_regex .opts .$opt .optional" $menu_path_file)
    if [ "$optional" = "true" ]; then
      optional_opts+="$opt "
    fi
  done

  # Generate the command to display
  if [[ -n $optional_opts ]]; then
    cmd_options+="{"
    for opt in $optional_opts; do
      cmd_options+="$opt|"
    done
    cmd_options="${cmd_options::-1}} "
  fi

  [[ $MENU_DEBUG -eq 1 ]] && echo "optional_opts: $optional_opts"
  [[ $show -eq 1 ]] && echo "$cmd_options"

  return 0
}

# @description Build the command with the regular expression.
#
# @arg $1 string Configuration file path.
# @arg $2 boolean Show the generated command (default **false**).
# @arg $3 string A regular expression.
build_cmd_opts() {
  local menu_path_file=$1
  local show=${2:-0}
  # shellcheck disable=SC2124
  local opts_regex=${@:3: $#-1}
  local parameters=""
  local opts=""
  local debug_parameters=""
  local debug_opts=""

  [[ ! -f $menu_path_file ]] && die "Please provide a menu configuration file" && return 1

  [[ $MENU_DEBUG -eq 1 ]] && echo "opts_regex: $opts_regex"

  # Get parameters from the menu configuration file
  if [ -z "$opts_regex" ]; then
    parameters=$(yq "keys | .[]" $menu_path_file)
  else
    parameters=$(yq "$opts_regex | keys | .[]" $menu_path_file)
  fi

  # Debug parameters
  if [ $MENU_DEBUG -eq 1 ]; then
    debug_parameters="parameters: "
    for parameter in $parameters; do debug_parameters+="$parameter "; done
    echo $debug_parameters
  fi

  # Generate the command to display
  for parameter in $parameters; do
    if [ $parameter = "opts" ]; then
      yq "$opts_regex .opts | keys" $menu_path_file &> /dev/null
      [[ $? -eq 1 ]] && die "Entry $opts_regex.opts is empty in $menu_path_file" && return 1
      opts=$(yq "$opts_regex .opts | keys | .[]" $menu_path_file)
      if [ $MENU_DEBUG -eq 1 ]; then
        debug_opts="opts: "
        for opt in $opts; do debug_opts+="$opt "; done
        echo $debug_opts
      fi
      build_mandatory_opts $menu_path_file 0 $opts
      build_optional_opts $menu_path_file 0 $opts
    fi
  done

  [[ $show -eq 1 ]] && echo "$cmd_options"
  return 0
}

# @description Show the help menu in standard output.
#
# @arg $1 string Configuration file path.
# @arg $2 array Options passed to script.
#
# Returns the help menu.
display_help() {
  local menu_path_file="$1"
  # shellcheck disable=SC2124
  local menu_opts=${@:2: $#-1}
  local opts_regex=""
  local cmd_options=""

  [[ ! -f $menu_path_file ]] && die "Please provide a menu configuration file" && return 1
  ! check_menu_entries $menu_path_file $menu_opts && display_help $menu_path_file && exit 1
  menu_name=$(yq '.name' $menu_path_file)

  # Build the regular expression
  for menu_opt in $menu_opts; do
    opts_regex+=".opts .$menu_opt "
    cmd_options+="$menu_opt "
  done

  # Build the command with options passed to script
  ! build_cmd_opts "$menu_path_file" 0 "$opts_regex" && exit 1
  [[ $MENU_DEBUG -eq 1 ]] && echo "cmd_options: $cmd_options"

  # Show the usage command
  show_message "Usage: $menu_name $cmd_options"
}

# @description Show the help menu in standard output with environment file.
_display_help() {
  display_help $CONFIG_FOLDER/$MENU_FOLDER/$MENU_FILE "$*"
}

main "$@"
