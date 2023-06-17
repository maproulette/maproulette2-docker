#!/bin/bash

set -exuo pipefail

# The VERSION can be set with an environment variable. If it's not set, use $1
export VERSION=${VERSION:-$1}
# Git branches may contains forward slashes and that don't work with docker. Replace any slashes with a dash.
export IMAGE_TAG=${VERSION//\//-}

if [[ "${USE_HOST_NETWORK}" == "true" ]]; then
  dockerNetworkArg="--network=host"
else
  dockerNetworkArg="--network mrnet -p 3000:3000"
fi

if [ "$(docker ps -qa -f name=maproulette-frontend)" ]; then
  echo "Removing existing maproulette-frontend container"
  docker stop maproulette-frontend
  docker rm maproulette-frontend
fi

echo "Starting maproulette frontend container"
docker run \
  -d \
  "${dockerNetworkArg}" \
  --name maproulette-frontend \
  --restart unless-stopped \
  maproulette/maproulette-frontend:"${IMAGE_TAG}"
