#!/bin/bash

set -exuo pipefail

export VERSION=$1
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

# Persist the @fastify/secure-session key across container restarts. Generated
# on first boot by setupServer.sh if the file is empty.
mkdir -p maproulette-secret
if [ ! -f maproulette-secret/secret-key ]; then
  touch maproulette-secret/secret-key
fi

echo "Starting maproulette api container"
docker run \
  -d \
  "${dockerNetworkArg[@]}" \
  --name maproulette-api \
  --restart unless-stopped \
  --env-file .env \
  --volume "$(pwd)/maproulette-secret/secret-key":/app/backend/secret-key \
  maproulette/maproulette-api:"${IMAGE_TAG}"
