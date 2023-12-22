#!/usr/bin/env bash

declare -A MSG_COLORS=(
  [NOCOLOR]='\033[0m'
  [GREEN]='\033[0;32m'
  [RED]='\033[0;31m'
  [ORANGE]='\033[0;33m'
)

# Print a message to STDOUT. You can customize the output by specifying a level.
#
# $1 - String messages that will be printed.
# $2 - An optional level (0: info (default), >0: error, <0: warn).
#
# Returns the formatted message.
show_message() {
  msg=$1
  level=${2:-0}
  # Check level option
  if ! [[ $level =~ ^-?[0-9]+$ ]] ; then { die "Invalid level option" && return 1; } fi
  # level=0: info message
  if [ "$level" -eq 0 ]; then msg_start="${MSG_COLORS[GREEN]}"; fi
  # level>0: error message
  if [ "$level" -gt 0 ]; then msg_start="${MSG_COLORS[RED]}"; fi
  # level<0: warn message
  if [ "$level" -lt 0 ]; then msg_start="${MSG_COLORS[ORANGE]}"; fi
  echo -e "$msg_start$msg${MSG_COLORS[NOCOLOR]}"
}

die() {
    echo -e "${MSG_COLORS[RED]}$*${MSG_COLORS[NOCOLOR]}" > /dev/stderr
}

# Read a confirm message and print a response ('y','') to STDOUT.
#
# $1 - String messages that will be prompted.
# $2 - Message to display if no answer is entered.
# $3 - Expected answer, used for unit test.
#
# Returns "y" if the user's response is "yes" or "y".
confirm_message() {
  default_answer=$2
  test_answer=$3
  if [ -z "$test_answer" ]; then
    read -r -p "$1" answer
  else
    if [ "$test_answer" = "no_answer" ]; then answer=""; else answer=$test_answer; fi
  fi
  if [ -z "$answer" ]; then
    echo "$default_answer" && exit
  fi
  case "$answer" in [yY][eE][sS]|[yY])
      echo "y"
      ;;
    *)
      echo ""
      ;;
  esac
}

"$@"
