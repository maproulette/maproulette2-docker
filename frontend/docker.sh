#!/bin/bash

set -exuo pipefail

# The VERSION can be set with an environment variable. If it's not set, use $1
export VERSION=${VERSION:-$1}
export IMAGE_TAG=${VERSION//\//-}
git=(${2//:/ })
CACHEBUST=${VERSION}

if [ ! -f ".env" ]; then
    echo "File .env does not exist!" >&2
    echo "Copy .env.template to .env at the repo root and fill in the values." >&2
    exit 1
fi

# Vite inlines VITE_* values at build time, so the .env must be inside the
# Docker build context.
cp .env frontend/.env

cd frontend
if [ "$VERSION" = "LATEST" ]; then
    CACHEBUST=$(git ls-remote "https://github.com/${git[1]}.git" | grep HEAD | cut -f 1)
fi

# When running everything on the host network, the frontend nginx talks to
# the backend over 127.0.0.1 instead of the mrnet container hostname.
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

rm -f .env
