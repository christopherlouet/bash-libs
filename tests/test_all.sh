#!/usr/bin/env bash

CURRENT_FOLDER=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
LIBS_FOLDER=$( cd -- $CURRENT_FOLDER/../libs &> /dev/null && pwd )
CONFIG_FOLDER=$( cd -- $LIBS_FOLDER/../config &> /dev/null && pwd )
LIBS_DOCKER_COMPOSE="$LIBS_FOLDER/docker_compose.sh"
LIBS_GITHUB="$LIBS_FOLDER/github.sh"
LIBS_MENU="$LIBS_FOLDER/menu.sh"
LIBS_MESSAGES="$LIBS_FOLDER/messages.sh"

# Messages
show_message() { bash "$LIBS_MESSAGES" "${FUNCNAME[0]}" "$@"; }
confirm_message() { bash "$LIBS_MESSAGES" "${FUNCNAME[0]}" "$@"; }
die() { bash "$LIBS_MESSAGES" "${FUNCNAME[0]}" "$@"; }

# Docker compose
init_docker_compose() { bash "$LIBS_DOCKER_COMPOSE" "init" "$@"; }
dc_exec_command() { bash "$LIBS_DOCKER_COMPOSE" "_dc_exec_command" "$@"; }

# Github
init_github() { bash "$LIBS_GITHUB" "init" "$@"; }
gh_release_verify() { bash "$LIBS_GITHUB" "_gh_release_verify" "$@"; }

# Menu
init_menu() { bash "$LIBS_MENU" "init" "$@"; }
display_help() { bash "$LIBS_MENU" "_display_help" "$@"; }

# Tests docker_compose
function test_docker_compose() {
  init_docker_compose "test" "docker_compose" "" "profile_test1" "test.env" "dc_test1"
  dc_exec_command 1 "start"
}

# Tests github
function test_github() {
  init_github "christopherlouet/bash-libs" "$CONFIG_FOLDER/github"
  gh_release_verify "v1.0.0"
}

# Tests menu
function test_menu() {
  init_menu "test" "menu" "menu.yml"
  display_help "test1"
}

# Launch the tests
function test_all() {
  test_docker_compose
  test_github
  test_menu
}

# Main function
function main() {
  if [ -z "$*" ]; then
    test_all
  else
    "$@"
  fi
}

main "$@"
