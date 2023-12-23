# utils.sh

A utility library.

## Overview

The library allows you to check the settings and environment file.

## Index

* [check_args](#checkargs)
* [load_env](#loadenv)
* [init_env](#initenv)
* [test_check_args](#testcheckargs)
* [_test_check_args_with_env](#testcheckargswithenv)

### check_args

Check if a function name exists.

#### Arguments

* **$1** (string): Function name.

### load_env

Load the environment variables with the .env file.

### init_env

Generate an environment file from an array of parameters.

#### Arguments

* **$1** (string): An environment file.
* **$2** (array): An array of parameters.

### test_check_args

Check arguments, used for unit test.

### _test_check_args_with_env

Check arguments with an environment file, used for unit test.

