#!/usr/bin/env bash

CURRENT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
GITHUB_ENV_FILE="$CURRENT_DIR/.github"
LIB_MESSAGES="$CURRENT_DIR/messages.sh"

show_message() { bash "$LIB_MESSAGES" "${FUNCNAME[0]}" "$@"; }
show_confirm_message() { bash "$LIB_MESSAGES" "${FUNCNAME[0]}" "$@"; }

_load_params() {
  if [ ! -f "$GITHUB_ENV_FILE" ]; then show_message "Environment file does not exist! ($GITHUB_ENV_FILE)" 1; fi
  # shellcheck source=libs/.github
  source "$GITHUB_ENV_FILE"
}

# Initialize environment variables for a github project. You can customize the project folder by specifying a path.
#
# $1 - Project name in github.
# $2 - An optional project folder.
#
# Examples:
# ./libs/github.sh "project/repository"                                   # Initialize the project in the parent folder
# ./libs/github.sh "project/repository" "$HOME/sources/myrepository"      # Initialize the project with this path
#
# Returns nothing.
init() {
  GITHUB_PROJECT_NAME=$1
  # Check arguments
  if [ -z "$GITHUB_PROJECT_NAME" ]; then show_message "Please provide the project path" 1; fi
  if [ -z "$2" ]; then
    PROJECT_FOLDER=$CURRENT_DIR/../$(echo "$GITHUB_PROJECT_NAME"|rev|cut -d"/" -f1|rev)
  else
    PROJECT_FOLDER=$2
  fi
  # Initializing environment variables
  GITHUB_BASE_URL=https://github.com
  GITHUB_API_URL=https://api.github.com/repos
  LIBS_FOLDER=$CURRENT_DIR
  PROJECT_API=$GITHUB_API_URL/$GITHUB_PROJECT_NAME
  PROJECT_API_TAGS=$PROJECT_API/tags
  PROJECT_API_RELEASES=$PROJECT_API/releases
  PROJECT_REPO=$GITHUB_BASE_URL/$GITHUB_PROJECT_NAME

  # Initializing the environment file
  cp /dev/null "$GITHUB_ENV_FILE"
  {
    echo "GITHUB_PROJECT_NAME=$GITHUB_PROJECT_NAME"
    echo "GITHUB_BASE_URL=$GITHUB_BASE_URL"
    echo "GITHUB_API_URL=$GITHUB_API_URL"
    echo "LIBS_FOLDER=$LIBS_FOLDER"
    echo "PROJECT_REPO=$PROJECT_REPO"
    echo "PROJECT_FOLDER=$PROJECT_FOLDER"
    echo "PROJECT_API=$PROJECT_API"
    echo "PROJECT_API_TAGS=$PROJECT_API_TAGS"
    echo "PROJECT_API_RELEASES=$PROJECT_API_RELEASES"
  } >> "$GITHUB_ENV_FILE"
}

# Name of last known release.
#
# Returns the latest release name.
release_latest() {
  _load_params
  release_latest=$(curl -s "$PROJECT_API_RELEASES/latest"|jq -r .tag_name)
  echo "$release_latest"
}

# Check if the release name exists.
#
# $1 - The release name.
#
# Returns the release name if it exists, otherwise returns empty.
release_verify() {
  _load_params
  release_name=$1
  if [ -z "$release_name" ]; then show_message "Please provide a release name" 1; fi
  release=$(curl  -s "$PROJECT_API_TAGS"|jq -r ".[]|select( .name == \"$release_name\" ).name")
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
    if [ -z "$release" ]; then show_message "'$release' is not a valid version!" 1; fi
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
  _load_params
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
