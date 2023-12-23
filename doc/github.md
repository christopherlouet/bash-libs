# github.sh

A library for manage a github project with an environment file.

## Overview

The library allows you to clone a github project by retrieving the parameters in an environment file.

## Index

* [load_env](#loadenv)
* [init](#init)
* [gh_api_rate](#ghapirate)
* [_gh_api_rate](#ghapirate)
* [gh_check_api_rate](#ghcheckapirate)
* [_gh_check_api_rate](#ghcheckapirate)
* [gh_release_latest](#ghreleaselatest)
* [_gh_release_latest](#ghreleaselatest)
* [gh_release_verify](#ghreleaseverify)
* [_gh_release_verify](#ghreleaseverify)
* [_gh_release_choice](#ghreleasechoice)
* [gh_clone](#ghclone)
* [_gh_clone](#ghclone)
* [_gh_clone_with_prompt](#ghclonewithprompt)

### load_env

Load the environment variables with the .env file.

### init

Initialize environment variables for a github project.

#### Example

```bash
./libs/github.sh init "project/repository"
./libs/github.sh init "project/repository" "config/myrepository"
```

#### Arguments

* **$1** (string): Project name in github.
* **$2** (string): A project folder (default config/project_name).
* **$3** (string): An API token (optional).

### gh_api_rate

Get current data rate.

#### Arguments

* **$1** (string): An API token (optional).
* **$2** (boolean): Display a message (default **true**).

### _gh_api_rate

Get current data rate with the environment file.

#### Arguments

* **$1** (boolean): Display a message (default **true**).

### gh_check_api_rate

Check API rate limit.

#### Arguments

* **$1** (string): An API token (optional).
* **$2** (boolean): Display a message (default **true**).

### _gh_check_api_rate

Check API rate limit with the environment file.

#### Arguments

* **$1** (boolean): Display a message (default **true**).

### gh_release_latest

Get last known release name.

#### Arguments

* **$1** (string): The github project name.
* **$2** (string): An API token (optional).
* **$3** (boolean): Display a message (default **true**).

### _gh_release_latest

Get last known release name with the environment file.

#### Arguments

* **$1** (boolean): Display a message (default **true**).

### gh_release_verify

Check if the release name exists.

#### Arguments

* **$1** (string): The github project name.
* **$2** (string): The release name.
* **$3** (string): An API token (optional).
* **$4** (boolean): Display a message (default **true**).

### _gh_release_verify

Check if the release name exists with the environment file.

#### Arguments

* **$1** (string): The release name.
* **$2** (boolean): Display a message (default **true**).

### _gh_release_choice

Prompt the user for the name of the release to retrieve.

#### Arguments

* **$1** (string): fake answer for unit test.

### gh_clone

Clone a github project.

#### Arguments

* **$1** (string): The repository to clone from.
* **$2** (string): The name of a new directory to clone into.
* **$3** (string): A tag or branch name (optional).
* **$4** (boolean): Display a message (default **true**).

### _gh_clone

Clone a github project with the environment file.

#### Arguments

* **$1** (string): A tag or branch name (optional).
* **$2** (boolean): Display a message (default **true**).

### _gh_clone_with_prompt

Clone a github project.

#### Example

```bash
./libs/github.sh _clone_with_prompt        # Clone the latest release with a user confirmation
./libs/github.sh _clone_with_prompt "" 0   # Clone the latest release without a user confirmation
./libs/github.sh _clone_with_prompt 1.0.0  # Clone the 1.0.0 release with a user confirmation
```

#### Arguments

* **$1** (string): A tag or branch name.
* **$2** (boolean): An optional user confirmation (0: no, 1: yes, default: 1)

