# messages.sh

A library for display messages.

## Overview

The library allows you to display custom messages.

## Index

* [show_message](#showmessage)
* [die](#die)
* [confirm_message](#confirmmessage)

### show_message

Print a message to STDOUT. You can customize the output by specifying a level.

#### Arguments

* **$1** (string): Message that will be printed.
* **$2** (int): An optional level (0: info (default), >0: error, <0: warn).

### die

Print a message to STDERR.

#### Arguments

* **$1** (string): Message that will be printed.

### confirm_message

Read a confirm message and print a response ('y','') to STDOUT.

#### Arguments

* **$1** (string): Message that will be prompted.
* **$2** (string): Message to display if no answer is entered.
* **$3** (string): Expected answer, used for unit test.

