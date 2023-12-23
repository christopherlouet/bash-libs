#!/usr/bin/env bash

libs="docker_compose github menu messages utils"

for lib in $libs; do
  ./shdoc < libs/$lib.sh > doc/$lib.md
done
