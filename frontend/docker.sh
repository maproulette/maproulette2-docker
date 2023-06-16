#!/bin/bash

set -exuo pipefail

# The VERSION can be set with an environment variable. If it's not set, use $1
export VERSION=${VERSION:-$1}
# Git branches may contains forward slashes and that don't work with docker. Replace any slashes with a dash.
export IMAGE_TAG=${VERSION//\//-}
git=(${2//:/ })
CACHEBUST=${VERSION}

if [ ! -f "frontend/env.production" ]; then
    echo "File frontend/env.production does not exist!" >&2
    echo "Copy frontend/env.template.production and rename it as frontend/env.production, and override as necessary." >&2
    exit 1
fi

if [ ! -f "frontend/customLayers.json" ]; then
    echo "File frontend/customLayers.json does not exist, creating the file with content '[]'"
    echo "For more information about map layers, see https://github.com/maproulette/maproulette3#adding-additional-and-custom-map-layers"
    echo "[]" > frontend/customLayers.json
fi

cd frontend
if [ "$VERSION" = "LATEST" ]; then
    CACHEBUST=$(git ls-remote https://github.com/maproulette/maproulette3.git | grep HEAD | cut -f 1)
fi

# If the container is using the host network, replace the nginx-config server to use localhost
if [[ "${USE_HOST_NETWORK}" == "true" ]]; then
  echo "Replacing the nginx-config server to use localhost"
  sed -i 's/server maproulette-api:9000;/server 127.0.0.1:9000;/g' nginx-config
fi

echo "Building container image for MapRoulette frontend Version: $IMAGE_TAG, Repo: ${git[1]}"
docker build \
    --pull \
    -t maproulette/maproulette-frontend:"${IMAGE_TAG}" \
    --build-arg VERSION="${VERSION}" \
    --build-arg GIT="${git[1]}" \
    --build-arg CACHEBUST="${CACHEBUST}" \
    .
