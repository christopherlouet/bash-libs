#!/usr/bin/env bash

LIBS_FOLDER=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
LIBS_MESSAGES="$LIBS_FOLDER/messages.sh"
LIBS_UTILS="$LIBS_FOLDER/utils.sh"
SCRIPT_NAME="$(basename -- "${BASH_SOURCE[0]}")"
ENV_FILE="$LIBS_FOLDER/.${SCRIPT_NAME%.*}"
GITHUB_BASE_URL=https://github.com
GITHUB_API_URL=https://api.github.com

check_function_params() { bash "$LIBS_UTILS" "${FUNCNAME[0]}" "$@"; }
init_env() { bash "$LIBS_UTILS" "${FUNCNAME[0]}" "$@"; }
load_env() {
  # shellcheck source=libs/.github
  source "$ENV_FILE"
}

# Message functions
show_message() { bash "$LIBS_MESSAGES" "${FUNCNAME[0]}" "$@"; }
confirm_message() { bash "$LIBS_MESSAGES" "${FUNCNAME[0]}" "$@"; }

# Initialize environment variables for a github project. You can customize the project folder by specifying a path.
#
# $1 - Project name in github.
# $2 - An optional project folder.
# $3 - An optional api token
#
# Examples:
# ./libs/github.sh "project/repository"                                   # Initialize the project in the parent folder
# ./libs/github.sh "project/repository" "$HOME/sources/myrepository"      # Initialize the project with this path
#
# Returns nothing.
init() {
  # Project name
  GITHUB_PROJECT_NAME=$1 && [[ -z "$GITHUB_PROJECT_NAME" ]] &&
    { show_message "Please provide the project path" 1; exit $?; }
  # Project folder
  PROJECT_FOLDER=${2:-$LIBS_FOLDER/../$(echo "$GITHUB_PROJECT_NAME"|rev|cut -d"/" -f1|rev)}
  # Api token
  GITHUB_API_TOKEN=$3
  # Project API url
  PROJECT_API_URL="$GITHUB_API_URL/repos/$GITHUB_PROJECT_NAME"
  # Initializing environment variables
  declare -A ENV_PARAMS=(
    [LIBS_FOLDER]=$LIBS_FOLDER
    [GITHUB_PROJECT_NAME]=$GITHUB_PROJECT_NAME
    [GITHUB_BASE_URL]=$GITHUB_BASE_URL
    [GITHUB_API_URL]=$GITHUB_API_URL
    [GITHUB_API_TOKEN]=$GITHUB_API_TOKEN
    [PROJECT_FOLDER]=$PROJECT_FOLDER
    [PROJECT_REPO]=$GITHUB_BASE_URL/$GITHUB_PROJECT_NAME
    [PROJECT_API_URL]=$PROJECT_API_URL
    [PROJECT_API_RELEASES]="$PROJECT_API_URL/releases"
    [PROJECT_API_TAGS]="$PROJECT_API_URL/tags"
  )
  init_env "$ENV_FILE" "$(declare -p ENV_PARAMS)"
}

# Check API rate limit.
#
# $1 - An optional API token.
#
# Returns ok if not API rate limit exceeded.
_check_api_rate() {
  load_env
  GITHUB_API_TOKEN=$1
  GITHUB_RATE_URL="$GITHUB_API_URL/rate_limit"
  GITLAB_HEADERS="-H \"Accept: application/vnd.github+json\" -H \"X-GitHub-Api-Version: 2022-11-28\""
  if [ -z "$GITHUB_API_TOKEN" ]; then
    GITLAB_HEADERS="$GITLAB_HEADERS -H \"Authorization: Bearer $GITHUB_API_TOKEN\""
  fi

  GITHUB_RATE=$(curl -sL "$GITLAB_HEADERS" $GITHUB_RATE_URL | jq '.rate')
  GITHUB_RATE_LIMIT=$(echo "$GITHUB_RATE"|jq '.limit')
  GITHUB_RATE_USED=$(echo "$GITHUB_RATE"|jq '.used')

  if [ "$GITHUB_RATE_USED" -lt "$GITHUB_RATE_LIMIT" ]; then
    show_message "ok"
  else
    show_message "API rate limit exceeded" 1; exit $?;
  fi
}

# Name of last known release.
#
# Returns the latest release name.
_release_latest() {
  load_env
  release_latest=$(curl -s "$PROJECT_API_RELEASES/latest"|jq -r '.tag_name')
  echo "$release_latest"
}

# Check if the release name exists.
#
# $1 - The release name.
#
# Returns the release name if it exists, otherwise returns empty.
_release_verify() {
  load_env
  release_name=$1
  if [ -z "$release_name" ]; then show_message "Please provide a release name" 1; exit $?; fi
  release=$(curl -s "$PROJECT_API_TAGS"|jq -r ".[]|select( .name == \"$release_name\" ).name")
  echo "$release"
}

# Prompt the user for the name of the release to retrieve.
#
# Returns the release name.
release_choice() {
  test_answer=$1
  release=""
  while [ -z "$release" ]; do
    if [ -z "$test_answer" ]; then
      read -r -p "Enter release version: " release_response
    else
      if [ "$test_answer" = "no_answer" ]; then release_response=""; else release_response=$test_answer; fi
    fi
    release=$(release_verify "$release_response")
    if [ -z "$release" ]; then
      show_message "Not a valid version" 1;
      if [ -n "$test_answer" ]; then exit 1; fi
    fi
  done
  echo "$release"
}

# Clone a github project.
#
# $1 - The repository to clone from.
# $2 - The release name.
# $3 - The name of a new directory to clone into.
#
# Returns nothing.
clone() {
  repository=$1
  release=$2
  directory_target=$3
  if [ -d "$directory_target" ]; then
    show_message "Remove the $directory_target directory"
    rm -rf "$directory_target"
  fi
  show_message "Clone the github repository $repository ($release)"
  git clone --depth 1 --branch "$release" "$repository" "$directory_target" >&- 2>&-
}

# Clone a github project.
#
# $1 - The release name.
# $2 - An optional user confirmation (0: no, 1: yes, default: 1)
#
# Examples:
# ./libs/github.sh clone        # Clone the latest release with a user confirmation
# ./libs/github.sh clone "" 0   # Clone the latest release without a user confirmation
# ./libs/github.sh clone 1.0.0  # Clone the 1.0.0 release with a user confirmation
#
# Returns nothing.
_clone_verify() {
  release=$1
  # Check user confirmation variable before
  confirm_clone=${2:-1}
  # Retrieve latest release if not specified
  release=${release:-$(release_latest)}
  # Check release
  release_verify=$(release_verify "$release") && [[ -z "$release_verify" ]] &&
    { show_message "$release is not a valid version!" 1; exit $?; }
  # User confirmation before
  if [ "$confirm_clone" -eq 1 ]; then
    clone_latest=$(confirm_message "Clone the $release version of $GITHUB_PROJECT_NAME? [Y/n] " "y")
    [[ "$clone_latest" != "y" ]] && exit 0
  fi
  # Clone the project
  # shellcheck disable=SC2153
  clone "$PROJECT_REPO" "$release" "$PROJECT_FOLDER"
}

test() {
  echo "test"
}

check_function_params "$@" && "$@"
