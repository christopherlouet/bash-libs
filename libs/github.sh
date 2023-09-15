#!/usr/bin/env bash

CURRENT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
GITHUB_ENV_FILE="$CURRENT_DIR/.github"
LIB_MESSAGES="$CURRENT_DIR/messages.sh"
LIB_UTILS="$CURRENT_DIR/utils.sh"

show_message() { bash "$LIB_MESSAGES" "${FUNCNAME[0]}" "$@"; }
show_confirm_message() { bash "$LIB_MESSAGES" "${FUNCNAME[0]}" "$@"; }
init_env() { bash "$LIB_UTILS" "${FUNCNAME[0]}" "$@"; }
load_env() {
  # shellcheck source=libs/.github
  source "$GITHUB_ENV_FILE"
}

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
  GITHUB_PROJECT_NAME=$1
  # Project name
  if [ -z "$GITHUB_PROJECT_NAME" ]; then show_message "Please provide the project path" 1; fi
  # Project folder
  if [ -z "$2" ]; then
    PROJECT_FOLDER=$CURRENT_DIR/../$(echo "$GITHUB_PROJECT_NAME"|rev|cut -d"/" -f1|rev)
  else
    PROJECT_FOLDER=$2
  fi
  # Api token
  GITHUB_API_TOKEN=$3

  # Initializing environment variables
  GITHUB_BASE_URL=https://github.com
  GITHUB_API_URL=https://api.github.com/repos
  LIBS_FOLDER=$CURRENT_DIR
  PROJECT_API=$GITHUB_API_URL/$GITHUB_PROJECT_NAME

  declare -A ENV_PARAMS
  ENV_PARAMS[GITHUB_PROJECT_NAME]=$GITHUB_PROJECT_NAME
  ENV_PARAMS[GITHUB_BASE_URL]=$GITHUB_BASE_URL
  ENV_PARAMS[GITHUB_API_URL]=$GITHUB_API_URL
  ENV_PARAMS[GITHUB_API_TOKEN]=$GITHUB_API_TOKEN
  ENV_PARAMS[LIBS_FOLDER]=$LIBS_FOLDER
  ENV_PARAMS[PROJECT_REPO]=$GITHUB_BASE_URL/$GITHUB_PROJECT_NAME
  ENV_PARAMS[PROJECT_FOLDER]=$PROJECT_FOLDER
  ENV_PARAMS[PROJECT_API]=$PROJECT_API
  ENV_PARAMS[PROJECT_API_TAGS]=$PROJECT_API/tags
  ENV_PARAMS[PROJECT_API_RELEASES]=$PROJECT_API/releases

  init_env "$GITHUB_ENV_FILE" "$(declare -p ENV_PARAMS)"
}

# Check API rate limit.
#
# $1 - An optional API token.
#
# Returns ok if not API rate limit exceeded.
check_api_rate() {
  load_env
  if [ -n "$1" ]; then GITHUB_API_TOKEN=$1; fi
  GITHUB_RATE_URL="https://api.github.com/rate_limit"
  if [ -z "$GITHUB_API_TOKEN" ]; then
    GITHUB_RATE=$(curl -sL \
          -H "Accept: application/vnd.github+json" \
          -H "X-GitHub-Api-Version: 2022-11-28" \
          $GITHUB_RATE_URL | jq '.rate')
  else
    GITHUB_RATE=$(curl -sL \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer $GITHUB_API_TOKEN" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      $GITHUB_RATE_URL | jq '.rate')
  fi

  GITHUB_RATE_LIMIT=$(echo "$GITHUB_RATE"|jq '.limit')
  GITHUB_RATE_USED=$(echo "$GITHUB_RATE"|jq '.used')

  if [ "$GITHUB_RATE_USED" -lt "$GITHUB_RATE_LIMIT" ]; then
    show_message "ok"
  else
    show_message "API rate limit exceeded" 1
  fi
}

# Name of last known release.
#
# Returns the latest release name.
release_latest() {
  load_env
  release_latest=$(curl -s "$PROJECT_API_RELEASES/latest"|jq -r .tag_name)
  echo "$release_latest"
}

# Check if the release name exists.
#
# $1 - The release name.
#
# Returns the release name if it exists, otherwise returns empty.
release_verify() {
  load_env
  release_name=$1
  if [ -z "$release_name" ]; then show_message "Please provide a release name" 1; fi
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
      show_message "Not a valid version" 1
      if [ -n "$test_answer" ]; then exit 1; fi
    fi
  done
  echo "$release"
}

# Clone a github project.
#
# $1 - The release name.
# $2 - An optional user confirmation (0: no, 1: yes, default: yes)
#
# Examples:
# ./libs/github.sh clone        # Clone the latest release with a user confirmation
# ./libs/github.sh clone "" 0   # Clone the latest release without a user confirmation
# ./libs/github.sh clone 1.0.0  # Clone the 1.0.0 release with a user confirmation
#
# Returns nothing.
clone() {
  load_env
  release=$1
  # Check user confirmation variable before
  if [ -z "$2" ]; then confirm_clone=1; else confirm_clone="$2"; fi
  # Retrieve latest release if not specified
  if [ -z "$release" ]; then release=$(release_latest); fi
  # Check release
  release_verify=$(release_verify "$release")
  if [ -z "$release_verify" ]; then show_message "$release is not a valid version!" 1; fi
  # User confirmation before
  if [ "$confirm_clone" -eq 1 ]; then
    clone_latest=$(show_confirm_message "Clone the $release version of $GITHUB_PROJECT_NAME? [Y/n] " "y")
    if [ "$clone_latest" != "y" ]; then exit 0; fi
  fi
  show_message "Clone the $GITHUB_PROJECT_NAME project ($release)"
  show_message "rm -rf $PROJECT_FOLDER" -1 && \
    rm -rf "$PROJECT_FOLDER"
  show_message "git clone --depth 1 --branch $release $PROJECT_REPO $PROJECT_FOLDER" -1 && \
    git clone --depth 1 --branch "$release" "$PROJECT_REPO" "$PROJECT_FOLDER"
}

"$@"
