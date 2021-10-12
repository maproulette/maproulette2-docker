#!/bin/bash

set -exuo pipefail

# The VERSION can be set with an environment variable. If it's not set, use $1
export VERSION=${VERSION:-$1}

if [ "$(docker ps -qa -f name=maproulette-frontend)" ]; then
  echo "Removing existing maproulette-frontend container"
  docker stop maproulette-frontend
  docker rm maproulette-frontend
fi

echo "Starting maproulette frontend container"
docker run \
  -itd \
  --name maproulette-frontend \
  --network mrnet \
  --restart unless-stopped \
  -p 3000:80 \
  maproulette/maproulette-frontend:"${VERSION}"
