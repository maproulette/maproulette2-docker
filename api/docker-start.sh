#!/bin/bash

set -exuo pipefail

export VERSION=$1
# Git branches may contains forward slashes and that don't work with docker. Replace any slashes with a dash.
export IMAGE_TAG=${VERSION//\//-}

if [[ "${USE_HOST_NETWORK}" == "true" ]]; then
  dockerNetworkArg=(--network=host)
else
  dockerNetworkArg=(--network mrnet -p 9000:9000)
fi

if [ "$(docker ps -qa -f name=maproulette-api)" ]; then
  echo "Removing existing maproulette-api container"
  docker stop maproulette-api
  docker rm maproulette-api
fi

echo "Starting maproulette api container"
docker run \
  -d \
  "${dockerNetworkArg[@]}" \
  --name maproulette-api \
  --restart unless-stopped \
  maproulette/maproulette-api:"${IMAGE_TAG}"
