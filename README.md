[![MIT license](https://img.shields.io/badge/License-MIT-blue.svg)](https://github.com/christopherlouet/bash-libs/blob/main/LICENSE)

## About The Project

A suite of utility functions to make writing bash scripts easier.

## Usage

Example to display a help menu, from **libs/menu.sh**:

```bash
#!/usr/bin/env bash

CURRENT_FOLDER=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
LIBS_FOLDER=$( cd -- $CURRENT_FOLDER/libs &> /dev/null && pwd )
LIBS_MENU="$LIBS_FOLDER/menu.sh"

init_menu() { bash "$LIBS_MENU" "init" "$@"; }
display_help() { bash "$LIBS_MENU" "_display_help" "$@"; }

function test_display_help() {
  init_menu "test" "menu" "menu.yml"
  display_help "test1"
}

test_display_help
```

More examples can be found in the **tests/test_all.sh** script.

## Libraries

* libs/docker_compose.sh
* libs/github.sh
* libs/menu.sh
* libs/messages.sh
* libs/utils.sh

## API documentation

A documentation API is available in Markdown format for each library in the doc folder.

* [docker_compose](doc/docker_compose.md)
* [github](doc/github.md)
* [menu](doc/menu.md)
* [messages](doc/messages.md)
* [utils](doc/utils.md)

This was generated using shdoc, a documentation generator for bash/zsh/sh.

[shdoc GitHub project](https://github.com/reconquest/shdoc)

## Tests

The pytest framework is used to run the unit tests of bash functions.
We will use a Docker container based on a Python environment to run the tests.

To launch the tests, we will use the command:

```bash
./launch_tests.sh
```

## WIP

* ```installer.sh``` Import bash libraries from a curl command.
* ```libs/systemd.sh``` Bash library to configure a task using systemd.
* ```libs/log.sh``` Bash library to configure log writing.
* ```libs/ssh.sh``` Bash library to manage ssh access.

## License

Distributed under the MIT License.
