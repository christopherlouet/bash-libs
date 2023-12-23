# docker_compose.sh

A library for running docker compose commands with an environment file.

## Overview

The library allows you to launch a docker compose command by retrieving the parameters in an environment file.

## Index

* [load_env](#loadenv)
* [check_env](#checkenv)
* [init](#init)
* [dc_build_docker_compose](#dcbuilddockercompose)
* [_dc_build_options](#dcbuildoptions)
* [dc_exec_command](#dcexeccommand)
* [_dc_exec_command](#dcexeccommand)
* [dc_status](#dcstatus)
* [_dc_status](#dcstatus)
* [_dc_waiting_start](#dcwaitingstart)

### load_env

Load the environment variables with the .env file.

### check_env

Check if docker compose is installed,

### init

Initialize environment variables for a docker compose project.

#### Example

```bash
./libs/docker_compose.sh init "project_name"
```

#### Arguments

* **$1** (string): Project name.
* **$2** (string): A project folder (Default config/docker_compose).
* **$3** (string): A docker compose file (Default docker-compose.yml).
* **$4** (string): A docker compose profile (Optional).
* **$5** (string): A docker compose environment file (Optional).
* **$6** (string): A reference service to check the status (Optional).

### dc_build_docker_compose

Build a docker compose command.

#### Example

```bash
./libs/docker_compose.sh dc_build_docker_compose config/docker_compose/docker-compose.yml start --env-file .env.test
```

#### Arguments

* **$1** (string): Docker compose file path.
* **$2** (string): Command to launch.
* **$3** (array): Options to place.

### _dc_build_options

Generate options to pass in a docker compose command with **environment file**.

#### Example

```bash
./libs/docker_compose.sh _dc_build_options 1
```

#### Arguments

* **$1** (boolean): Show the options (Default false).
* **$2** (array): Options to pass.

### dc_exec_command

Execute or show a docker compose command.

#### Example

```bash
./libs/docker_compose.sh dc_exec_command config/docker_compose/docker-compose.yml 1 start --env-file .env.test
```

#### Arguments

* **$1** (string): Docker compose file path.
* **$2** (boolean): Show generated command (Default true).
* **$3** (string): Command to execute.
* **$4** (array): Options to pass.

### _dc_exec_command

Execute or show a docker compose command with **environment file**.

#### Example

```bash
./libs/docker_compose.sh _dc_exec_command 1 start
```

#### Arguments

* **$1** (boolean): Show generated command (Default true).
* **$2** (string): Command to execute
* **$3** (array): Options to pass.

### dc_status

Show the service status.

#### Example

```bash
./libs/docker_compose.sh dc_status config/docker_compose/docker-compose.yml dc_test1
```

#### Arguments

* **$1** (string): Docker compose file path.
* **$2** (string): Service name.

### _dc_status

Show the service status with **environment file**.

#### Example

```bash
./libs/docker_compose.sh _dc_status
```

### _dc_waiting_start

Show a prompt during container startup with **environment file**.

#### Example

```bash
./libs/docker_compose.sh _dc_waiting_start
```

