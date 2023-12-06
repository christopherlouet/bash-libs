#!/usr/bin/env bash

GITHUB_API_TOKEN=$1
DOCKER_IMAGE=bash_libs:1.0.0
DOCKER_BUILDKIT=1 docker build --target=runtime -t=$DOCKER_IMAGE .

if [ ! -f tests/.env ]; then
  echo "GITHUB_API_TOKEN=$GITHUB_API_TOKEN">tests/.env
fi

docker run --rm -it \
  -v "$(pwd)/libs:/app/libs" \
  -v "$(pwd)/tests:/app/tests" \
  -e PWD="/app" \
  $DOCKER_IMAGE pytest tests/test_*
