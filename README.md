[![MIT license](https://img.shields.io/badge/License-MIT-blue.svg)](https://github.com/christopherlouet/bash-libs/blob/main/LICENSE)

## About The Project

A suite of utility functions to make writing bash scripts easier.

## Usage

Example to import only the *show_message* function from messages.sh:

```bash
LIB_MESSAGES="./libs/messages.sh"
show_message() { bash "$LIB_MESSAGES" "${FUNCNAME[0]}" "$@"; }
```

Example to import all functions from messages.sh:

```bash
source "./libs/messages.sh"
```

## Libraries

### libs/messages.sh

WIP

### libs/github.sh

WIP

## Tests

The pytest framework is used to run the unit tests of bash functions.
We will use a Docker container based on a Python environment to run the tests.

To launch the tests, we will use the command:

```bash
./tests.sh
```

## WIP

* `install.sh` to import bash libraries from a curl command
* `libs/github.sh`
* `libs/docker_compose.sh`

## License

Distributed under the MIT License.
