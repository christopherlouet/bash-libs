# menu.sh

A library for manage a help menu with an environment file.

## Overview

The library allows you to display a help menu by retrieving the parameters from a yaml configuration file.

## Index

* [load_env](#loadenv)
* [check_env](#checkenv)
* [init](#init)
* [check_menu_entries](#checkmenuentries)
* [build_mandatory_opts](#buildmandatoryopts)
* [build_optional_opts](#buildoptionalopts)
* [build_cmd_opts](#buildcmdopts)
* [display_help](#displayhelp)
* [_display_help](#displayhelp)

### load_env

Load the environment variables with the .env file.

### check_env

Check if yq is installed, and install it if necessary.

### init

Initialize environment variables for a menu project.

#### Example

```bash
./libs/menu.sh init "project_name"  # Initialize the project
```

#### Arguments

* **$1** (string): Project name. (default **menu**).
* **$2** (string): Project folder (default **config/menu**).
* **$3** (string): Configuration file (default **menu.yml**).

### check_menu_entries

Check if the entry exists in the configuration file.

#### Arguments

* **$1** (string): Configuration file path.
* **$2** (array): Options passed to script.

### build_mandatory_opts

Build the command with the required options.

#### Arguments

* **$1** (string): Configuration file path.
* **$2** (boolean): Show the options (default **false**).
* **$3** (array): Options passed to script.

### build_optional_opts

Build the command with the optional options.

#### Arguments

* **$1** (string): Configuration file path.
* **$2** (boolean): Show the options (default **false**).
* **$3** (array): Options passed to script.

### build_cmd_opts

Build the command with the regular expression.

#### Arguments

* **$1** (string): Configuration file path.
* **$2** (boolean): Show the generated command (default **false**).
* **$3** (string): A regular expression.

### display_help

Show the help menu in standard output.

#### Arguments

* **$1** (string): Configuration file path.
* **$2** (array): Options passed to script.

### _display_help

Show the help menu in standard output with environment file.

