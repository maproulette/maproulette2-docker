#!/bin/bash

set -exuo pipefail

export VERSION=$1
# Git branches may contain forward slashes, which aren't valid in image tags.
export IMAGE_TAG=${VERSION//\//-}
git=(${2//:/ })
CACHEBUST=${VERSION}

if [ ! -f ".env" ]; then
    echo "File .env does not exist!" >&2
    echo "Copy .env.template to .env at the repo root and fill in the values." >&2
    exit 1
fi

cd api
if [ "$VERSION" = "LATEST" ]; then
    CACHEBUST=$(git ls-remote "https://github.com/${git[1]}.git" | grep HEAD | cut -f 1)
fi

echo "Building container image for MapRoulette API Version: $IMAGE_TAG, Repo: ${git[1]}"
docker build \
    --pull \
    --no-cache \
    -t maproulette/maproulette-api:"${IMAGE_TAG}" \
    --build-arg VERSION="${VERSION}" \
    --build-arg GIT="${git[1]}" \
    --build-arg CACHEBUST="${CACHEBUST}" \
    .
