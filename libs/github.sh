#!/usr/bin/env bash

LIBS_FOLDER=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
LIBS_MESSAGES="$LIBS_FOLDER/messages.sh"
LIBS_UTILS="$LIBS_FOLDER/utils.sh"
SCRIPT_NAME="$(basename -- "${BASH_SOURCE[0]}")"
ENV_FILE="$LIBS_FOLDER/.${SCRIPT_NAME%.*}"
GITHUB_BASE_URL="https://github.com"
GITHUB_API_URL="https://api.github.com"
GITHUB_API_REPOS_URL="$GITHUB_API_URL/repos"
GITHUB_API_RATE_URL="$GITHUB_API_URL/rate_limit"

main() { eval "$(bash "$LIBS_UTILS" "check_args" "$@") ; check_args $*" ; "$@"; }
init_env() { bash "$LIBS_UTILS" "${FUNCNAME[0]}" "$@"; }
check_var_is_defined() { bash "$LIBS_UTILS" "${FUNCNAME[0]}" "$@"; }

function load_env() {
  if [ ! -f "$ENV_FILE" ]; then
    show_message "Please initialize the environment file with the command '$SCRIPT_NAME init project_path'" 1; return 1;
  fi
  # shellcheck source=./github.sh
  source "$ENV_FILE"
}

# Message functions
show_message() { bash "$LIBS_MESSAGES" "${FUNCNAME[0]}" "$@"; }
confirm_message() { bash "$LIBS_MESSAGES" "${FUNCNAME[0]}" "$@"; }

# Initialize environment variables for a github project. You can customize the project folder by specifying a path.
#
# $1 - Project name in github.
# $2 - A project folder (optional).
# $3 - An API token (optional).
#
# Examples:
# ./libs/github.sh "project/repository"                                   # Initialize the project in the parent folder
# ./libs/github.sh "project/repository" "$HOME/sources/myrepository"      # Initialize the project with this path
#
# Returns nothing.
init() {
  # Project name
  GITHUB_PROJECT_NAME=$1 && [[ -z "$GITHUB_PROJECT_NAME" ]] &&
    { show_message "Please provide the project path" 1 && return 1; }
  # Project folder
  PROJECT_FOLDER=${2:-$LIBS_FOLDER/../$(echo "$GITHUB_PROJECT_NAME"|rev|cut -d"/" -f1|rev)}
  # Api token
  GITHUB_API_TOKEN=$3
  # Project API url
  PROJECT_API_URL="$GITHUB_API_REPOS_URL/$GITHUB_PROJECT_NAME"
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
    [PROJECT_API_RELEASES]="$GITHUB_API_RELEASES_URL"
    [PROJECT_API_TAGS]="$GITHUB_API_TAGS_URL"
  )
  init_env "$ENV_FILE" "$(declare -p ENV_PARAMS)"
}

# Get current data rate.
#
# $1 - An API token (optional).
# $2 - Display a message (optional).
#
# Returns current data rate.
api_rate() {
  github_api_token=$1
  api_rate_show=${2:-1}
  [[ $api_rate_show -eq 1 ]] && declare -A data_api_rate
  if [ -n "$github_api_token" ]; then
    response=$(curl -s -H 'Accept: application/vnd.github+json' \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      -H "Authorization: Bearer $github_api_token" \
      --compressed "$GITHUB_API_RATE_URL")
  else
    response=$(curl -s -H 'Accept: application/vnd.github+json' \
          -H "X-GitHub-Api-Version: 2022-11-28" \
          --compressed "$GITHUB_API_RATE_URL")
  fi
  message=$(echo $response | jq '.message')
  if [ "$message" = "null" ]; then
      rate=$(echo "$response"|jq '.rate')
  else
    [[ $api_rate_show -eq 1 ]] && show_message "${message//\"/}" 1
    return 1
  fi
  data_api_rate=(
    [LIMIT]=$(echo "$rate"|jq '.limit')
    [USED]=$(echo "$rate"|jq '.used')
    [REMAINING]=$(echo "$rate"|jq '.remaining')
    [RESET]=$(echo "$rate"|jq '.reset')
  )
  if [ $api_rate_show -eq 1 ]; then
    for data in "${!data_api_rate[@]}"; do
      echo "$data=${data_api_rate[$data]}"
    done
  fi
}

# Get current data rate with the environment file.
#
# $1 - Display a message (optional).
#
# Returns current data rate.
_api_rate() {
  api_rate "$GITHUB_API_TOKEN" $1
}

# Check API rate limit.
#
# $1 - An API token (optional).
# $2 - Display a message (optional).
#
# Returns 1 if API rate limit exceeded.
check_api_rate() {
  github_api_token=$1
  check_api_rate_show=${2:-1}

  declare -A data_api_rate
  api_rate $github_api_token 0
  if [ $? -eq 1 ]; then
    [[ $check_api_rate_show -eq 1 ]] && show_message "Erreur api_rate" 1
    return 1
  fi
  rate_limit=${data_api_rate[LIMIT]}
  rate_used=${data_api_rate[USED]}

  if [ "$rate_used" -lt "$rate_limit" ]; then
    [[ $check_api_rate_show -eq 1 ]] && show_message "ok"
    return 0
  else
    [[ $check_api_rate_show -eq 1 ]] && show_message "API rate limit exceeded" 1
    return 1
  fi
}

# Check API rate limit with the environment file.
#
# $1 - Display a message (optional).
#
# Returns 1 if API rate limit exceeded.
_check_api_rate() {
  check_api_rate "$GITHUB_API_TOKEN" $1
}

# Get last known release name.
#
# $1 - The github project name.
# $2 - An API token (optional).
# $3 - Display a message (optional).
#
# Returns the latest release name.
release_latest() {
  github_project_name=$1
  github_api_token=$2
  release_latest_show=${3:-1}
  [[ -z "$github_project_name" ]] && show_message "Please provide a github project name" 1 && return 1
  check_api_rate "$github_api_token" 0
  release_latest_api_url="$GITHUB_API_REPOS_URL/$github_project_name/releases/latest"
  if [ -n "$github_api_token" ]; then
    response=$(curl -s -H 'Accept: application/vnd.github+json' \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      -H "Authorization: Bearer $github_api_token" \
      --compressed "$release_latest_api_url")
  else
    response=$(curl -s -H 'Accept: application/vnd.github+json' \
          -H "X-GitHub-Api-Version: 2022-11-28" \
          --compressed "$release_latest_api_url")
  fi
  release_latest=$(echo $response|jq -r '.tag_name')
  [[ $release_latest_show -eq 1 ]] && show_message "$release_latest"
  return 0
}

# Get last known release name with the environment file.
#
# $1 - Display a message (optional).
#
# Returns the latest release name.
_release_latest() {
  release_latest "$GITHUB_PROJECT_NAME" "$GITHUB_API_TOKEN" "$1"
}

# Check if the release name exists.
#
# $1 - The github project name.
# $2 - The release name.
# $3 - An API token (optional).
# $4 - Display a message (optional).
#
# Returns 1 if release name not exists.
release_verify() {
  github_project_name=$1
  release_name=$2
  github_api_token=$3
  release_verify_show=${4:-1}
  [[ -z "$github_project_name" ]] && show_message "Please provide a github project name" 1 && return 1
  [[ -z "$release_name" ]] && show_message "Please provide a release name" 1 && return 1
  project_tags_api_url="$GITHUB_API_REPOS_URL/$github_project_name/tags"
  if [ -n "$github_api_token" ]; then
    response=$(curl -s -H 'Accept: application/vnd.github+json' \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      -H "Authorization: Bearer $github_api_token" \
      --compressed "$project_tags_api_url")
  else
    response=$(curl -s -H 'Accept: application/vnd.github+json' \
          -H "X-GitHub-Api-Version: 2022-11-28" \
          --compressed "$project_tags_api_url")
  fi
  release_verify=$(echo $response|jq -r ".[]|select( .name == \"$release_name\" ).name")
  if [ -z $release_verify ]; then
    [[ $release_verify_show -eq 1 ]] && show_message "$release_name not exist" 1
    return 1
  else
    [[ $release_verify_show -eq 1 ]] && show_message "$release_name exist"
    return 0
  fi
}

# Check if the release name exists with the environment file.
#
# $1 - The release name.
# $2 - Display a message (optional).
#
# Returns 1 if release name not exists.
_release_verify() {
  release_verify "$GITHUB_PROJECT_NAME" "$1" "$GITHUB_API_TOKEN" "$2"
}

# Prompt the user for the name of the release to retrieve.
#
# Returns the release name.
_release_choice() {
  test_answer=$1
  release=""
  while [ -z "$release" ]; do
    if [ -z "$test_answer" ]; then
      read -r -p "Enter release version: " release_response
    else
      if [ "$test_answer" = "no_answer" ]; then release_response=""; else release_response=$test_answer; fi
    fi
    _release_verify "$release_response" 0
    if [ $? -eq 1 ]; then
      show_message "Not a valid version" 1;
      if [ -n "$test_answer" ]; then return 1; fi
    else
      return 0
    fi
  done
  echo "$release_response"
}

# Clone a github project.
#
# $1 - The repository to clone from.
# $2 - The name of a new directory to clone into.
# $3 - A tag or branch name (optional).
# $4 - Display a message (optional).
#
# Returns nothing.
clone() {
  repository=$1
  directory_target=$2
  tag=$3
  clone_show=${4:-1}
  [[ -z "$repository" ]] && show_message "Please provide a repository name" 1 && return 1
  [[ -z "$directory_target" ]] && show_message "Please provide a directory target" 1 && return 1
  if [ -d "$directory_target" ]; then
    [[ $clone_show -eq 1 ]] && show_message "Remove the $directory_target directory"
    rm -rf "$directory_target"
  fi
  if [ -z $tag ]; then
    [[ $clone_show -eq 1 ]] && show_message "Clone the github repository $repository"
    git clone --depth 1 "$repository" "$directory_target" >&- 2>&-
  else
    [[ $clone_show -eq 1 ]] && show_message "Clone the github repository $repository ($tag)"
    git clone --depth 1 --branch "$tag" "$repository" "$directory_target" >&- 2>&-
  fi
}

# Clone a github project with the environment file.
#
# $1 - A tag or branch name (optional).
# $2 - Display a message (optional).
#
# Returns nothing.
_clone() {
  clone "$PROJECT_REPO" "$PROJECT_FOLDER" "$1" "$2"
}

# Clone a github project.
#
# $1 - A tag or branch name.
# $2 - An optional user confirmation (0: no, 1: yes, default: 1)
#
# Examples:
# ./libs/github.sh _clone_with_prompt        # Clone the latest release with a user confirmation
# ./libs/github.sh _clone_with_prompt "" 0   # Clone the latest release without a user confirmation
# ./libs/github.sh _clone_with_prompt 1.0.0  # Clone the 1.0.0 release with a user confirmation
#
# Returns nothing.
_clone_with_prompt() {
  tag=$1
  # Check user confirmation variable before
  confirm_clone=${2:-1}
  # Retrieve latest release if not specified
  _release_latest 0
  tag=${tag:-$release_latest}
  # Check release
  _release_verify "$tag" 0
  [[ $? -eq 1 ]] && { show_message "$tag is not a valid tag or branch!" 1 && return 1; }
  # User confirmation before
  if [ "$confirm_clone" -eq 1 ]; then
    clone_latest=$(confirm_message "Clone the $tag branch of $GITHUB_PROJECT_NAME? [Y/n] " "y")
    [[ "$clone_latest" != "y" ]] && return 0
  fi
  # Clone the project
  _clone "$tag"
}

main "$@"
