#!/usr/bin/env bash

EXEC_CMD=$@
CONTAINER_NAME=bash_libs_test
DOCKER_IMAGE=bash_libs:1.0.0

if [ "${@: -1}" = "--force" ]; then
  docker image rm $DOCKER_IMAGE 2> /dev/null
  EXEC_CMD=${@:1: $#-1}
fi

[[ -z $EXEC_CMD ]] && EXEC_CMD="pytest tests/test_*.py"

echo "Build $DOCKER_IMAGE"
DOCKER_BUILDKIT=1 docker build --target=runtime -t=$DOCKER_IMAGE .

command="docker run --rm -it --name $CONTAINER_NAME --privileged --user=root \
  -v /var/run/docker.sock:/var/run/docker.sock:rw \
  -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
  -v "$(pwd)/libs:/app/libs" \
  -v "$(pwd)/tests:/app/tests" \
  -e PWD=/app $DOCKER_IMAGE $EXEC_CMD"

echo "$command" && eval "$command"
