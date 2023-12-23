#!/usr/bin/env bash
# @file github.sh
# @brief A library for manage a github project with an environment file.
# @description
#     The library allows you to clone a github project by retrieving the parameters in an environment file.

LIBS_FOLDER=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
CONFIG_FOLDER=$( cd -- $LIBS_FOLDER/../config &> /dev/null && pwd )
ENV_FOLDER=$( cd -- $LIBS_FOLDER/../env &> /dev/null && pwd )
LIBS_MESSAGES="$LIBS_FOLDER/messages.sh"
LIBS_UTILS="$LIBS_FOLDER/utils.sh"
SCRIPT_NAME="$(basename -- "${BASH_SOURCE[0]}")"
ENV_FILE="$ENV_FOLDER/.${SCRIPT_NAME%.*}"
GITHUB_BASE_URL="https://github.com"
GITHUB_API_URL="https://api.github.com"
GITHUB_API_REPOS_URL="$GITHUB_API_URL/repos"
GITHUB_API_RATE_URL="$GITHUB_API_URL/rate_limit"

main() { eval "$(bash "$LIBS_UTILS" "check_args" "$@") ; check_args $*" ; "$@"; }
show_message() { bash "$LIBS_MESSAGES" "${FUNCNAME[0]}" "$@"; }
confirm_message() { bash "$LIBS_MESSAGES" "${FUNCNAME[0]}" "$@"; }
die() { bash "$LIBS_MESSAGES" "${FUNCNAME[0]}" "$@"; }
init_env() { bash "$LIBS_UTILS" "${FUNCNAME[0]}" "$@"; }

# @description Load the environment variables with the .env file.
function load_env() {
  if [ ! -f "$ENV_FILE" ]; then
    die "Please initialize the environment file with the command '$SCRIPT_NAME init project_path'" ; exit 1;
  fi
  # shellcheck source=./github.env
  source "$ENV_FILE"
}

# @description Initialize environment variables for a github project.
#
# @arg $1 string Project name in github.
# @arg $2 string A project folder (default config/project_name).
# @arg $3 string An API token (optional).
#
# @example
# ./libs/github.sh init "project/repository"
# ./libs/github.sh init "project/repository" "config/myrepository"
init() {
  # Project name
  GITHUB_PROJECT_NAME=$1
  # Project folder
  GITHUB_PROJECT_FOLDER=$CONFIG_FOLDER/${2:-$(echo "$GITHUB_PROJECT_NAME"|rev|cut -d"/" -f1|rev)}
  # Api token
  GITHUB_API_TOKEN=$3
  [[ -z "$GITHUB_PROJECT_NAME" ]] && die "Please provide the project path" && return 1
  # Project repo url
  GITHUB_PROJECT_REPO="$GITHUB_BASE_URL/$GITHUB_PROJECT_NAME"
  # Project API url
  GITHUB_PROJECT_API_URL="$GITHUB_API_REPOS_URL/$GITHUB_PROJECT_NAME"
  # Initializing environment variables
  declare -A ENV_PARAMS=(
    [GITHUB_PROJECT_NAME]=$GITHUB_PROJECT_NAME
    [GITHUB_PROJECT_FOLDER]=$GITHUB_PROJECT_FOLDER
    [GITHUB_API_TOKEN]=$GITHUB_API_TOKEN
    [GITHUB_PROJECT_REPO]=$GITHUB_PROJECT_REPO
    [GITHUB_PROJECT_API_URL]=$GITHUB_PROJECT_API_URL
  )
  init_env "$ENV_FILE" "$(declare -p ENV_PARAMS)"
}

# @description Get current data rate.
#
# @arg $1 string An API token (optional).
# @arg $2 boolean Display a message (default **true**).
gh_api_rate() {
  local github_api_token=$1
  local api_rate_show=${2:-1}
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

# @description Get current data rate with the environment file.
#
# @arg $1 boolean Display a message (default **true**).
#
# Returns current data rate.
_gh_api_rate() {
  gh_api_rate "$GITHUB_API_TOKEN" ${1:-1}
}

# @description Check API rate limit.
#
# @arg $1 string An API token (optional).
# @arg $2 boolean Display a message (default **true**).
#
# Returns 1 if API rate limit exceeded.
gh_check_api_rate() {
  local github_api_token=$1
  local check_api_rate_show=${2:-1}
  declare -A data_api_rate
  gh_api_rate "$github_api_token" 0
  if [ $? -eq 1 ]; then
    [[ $check_api_rate_show -eq 1 ]] && die "Erreur api_rate"
    return 1
  fi
  rate_limit=${data_api_rate[LIMIT]}
  rate_used=${data_api_rate[USED]}
  if [ "$rate_used" -lt "$rate_limit" ]; then
    [[ $check_api_rate_show -eq 1 ]] && show_message "ok"
    return 0
  else
    [[ $check_api_rate_show -eq 1 ]] && die "API rate limit exceeded"
    return 1
  fi
}

# @description Check API rate limit with the environment file.
#
# @arg $1 boolean Display a message (default **true**).
_gh_check_api_rate() {
  gh_check_api_rate "$GITHUB_API_TOKEN" ${1:-1}
}

# @description Get last known release name.
#
# @arg $1 string The github project name.
# @arg $2 string An API token (optional).
# @arg $3 boolean Display a message (default **true**).
gh_release_latest() {
  local github_project_name=$1
  local github_api_token=$2
  local release_latest_show=${3:-1}

  [[ -z "$github_project_name" ]] && die "Please provide a github project name" && return 1

  gh_check_api_rate "$github_api_token" 0
  if [ -n "$github_api_token" ]; then
    response=$(curl -s -H 'Accept: application/vnd.github+json' \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      -H "Authorization: Bearer $github_api_token" \
      --compressed "$GITHUB_PROJECT_API_URL/releases/latest")
  else
    response=$(curl -s -H 'Accept: application/vnd.github+json' \
          -H "X-GitHub-Api-Version: 2022-11-28" \
          --compressed "$GITHUB_PROJECT_API_URL/releases/latest")
  fi

  release_latest=$(echo $response|jq -r '.tag_name')
  [[ $release_latest_show -eq 1 ]] && show_message "$release_latest"

  return 0
}

# @description Get last known release name with the environment file.
#
# @arg $1 boolean Display a message (default **true**).
#
# Returns the latest release name.
_gh_release_latest() {
  gh_release_latest "$GITHUB_PROJECT_NAME" "$GITHUB_API_TOKEN" ${1:-1}
}

# @description Check if the release name exists.
#
# @arg $1 string The github project name.
# @arg $2 string The release name.
# @arg $3 string An API token (optional).
# @arg $4 boolean Display a message (default **true**).
gh_release_verify() {
  local github_project_name=$1
  local release_name=$2
  local github_api_token=$3
  local release_verify_show=${4:-1}

  [[ -z "$github_project_name" ]] && die "Please provide a github project name" && return 1
  [[ -z "$release_name" ]] && die "Please provide a release name" && return 1

  gh_check_api_rate "$github_api_token" 0
  if [ -n "$github_api_token" ]; then
    response=$(curl -s -H 'Accept: application/vnd.github+json' \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      -H "Authorization: Bearer $github_api_token" \
      --compressed "$GITHUB_PROJECT_API_URL/tags")
  else
    response=$(curl -s -H 'Accept: application/vnd.github+json' \
          -H "X-GitHub-Api-Version: 2022-11-28" \
          --compressed "$GITHUB_PROJECT_API_URL/tags")
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

# @description Check if the release name exists with the environment file.
#
# @arg $1 string The release name.
# @arg $2 boolean Display a message (default **true**).
_gh_release_verify() {
  gh_release_verify "$GITHUB_PROJECT_NAME" "$1" "$GITHUB_API_TOKEN" ${2:-1}
}

# @description Prompt the user for the name of the release to retrieve.
#
# @arg $1 string fake answer for unit test.
_gh_release_choice() {
  local test_answer=$1
  local release=""
  while [ -z "$release" ]; do
    if [ -z "$test_answer" ]; then
      read -r -p "Enter release version: " release_response
    else
      if [ "$test_answer" = "no_answer" ]; then release_response=""; else release_response=$test_answer; fi
    fi
    _gh_release_verify "$release_response" 0
    if [ $? -eq 1 ]; then
      show_message "Not a valid version" 1;
      if [ -n "$test_answer" ]; then return 1; fi
    else
      return 0
    fi
  done
  echo "$release_response"
}

# @description Clone a github project.
#
# @arg $1 string The repository to clone from.
# @arg $2 string The name of a new directory to clone into.
# @arg $3 string A tag or branch name (optional).
# @arg $4 boolean Display a message (default **true**).
gh_clone() {
  local repository=$1
  local directory_target=$2
  local tag=$3
  local clone_show=${4:-1}

  [[ -z "$repository" ]] && die "Please provide a repository name" && return 1
  [[ -z "$directory_target" ]] && die "Please provide a directory target" && return 1

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

# @description Clone a github project with the environment file.
#
# @arg $1 string A tag or branch name (optional).
# @arg $2 boolean Display a message (default **true**).
#
# Returns nothing.
_gh_clone() {
  gh_clone "$GITHUB_PROJECT_REPO" "$GITHUB_PROJECT_FOLDER" "$1" ${2:-1}
}

# @description Clone a github project.
#
# @arg $1 string A tag or branch name.
# @arg $2 boolean An optional user confirmation (0: no, 1: yes, default: 1)
#
# @example
# ./libs/github.sh _clone_with_prompt        # Clone the latest release with a user confirmation
# ./libs/github.sh _clone_with_prompt "" 0   # Clone the latest release without a user confirmation
# ./libs/github.sh _clone_with_prompt 1.0.0  # Clone the 1.0.0 release with a user confirmation
#
# Returns nothing.
_gh_clone_with_prompt() {
  local tag=$1
  # Check user confirmation variable before
  local confirm_clone=${2:-1}
  # Retrieve latest release if not specified
  _gh_release_latest 0
  tag=${tag:-$release_latest}
  # Check release
  _gh_release_verify "$tag" 0
  [[ $? -eq 1 ]] && { die "$tag is not a valid tag or branch!" && return 1; }
  # User confirmation before
  if [ "$confirm_clone" -eq 1 ]; then
    clone_latest=$(confirm_message "Clone the $tag branch of $GITHUB_PROJECT_NAME? [Y/n] " "y")
    [[ "$clone_latest" != "y" ]] && return 0
  fi
  # Clone the project
  _clone "$tag"
}

main "$@"
