#!/bin/bash

set -exuo pipefail

export VERSION=$1

if [ "$(docker ps -qa -f name=maproulette-api)" ]; then
  echo "Removing existing maproulette-api container"
  docker stop maproulette-api
  docker rm maproulette-api
fi

echo "Starting maproulette api container"
docker run \
  -itd \
  --name maproulette-api \
  --network mrnet \
  --restart unless-stopped \
  -p 9000:9000 \
  maproulette/maproulette-api:"${VERSION}"
