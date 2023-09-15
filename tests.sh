#!/usr/bin/env bash

DOCKER_IMAGE=bash_libs:1.0.0
DOCKER_BUILDKIT=1 docker build --target=runtime -t=$DOCKER_IMAGE .

docker run --rm -it \
  -v "$(pwd)/libs:/app/libs" \
  -v "$(pwd)/tests:/app/tests" \
  $DOCKER_IMAGE pytest tests/
