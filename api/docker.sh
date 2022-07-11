#!/bin/bash

set -exuo pipefail

export VERSION=$1
# Git branches may contains forward slashes and that don't work with docker. Replace any slashes with a dash.
export IMAGE_TAG=${VERSION//\//-}
git=(${2//:/ })
CACHEBUST=${VERSION}

if [ ! -f "api/application-overrides.conf" ]; then
    echo "File api/application-overrides.conf does not exist!" >&2
    echo "Copy api/application-overrides.template.conf and rename it as api/application-overrides.conf, and override as necessary." >&2
    exit 1
fi

cd api
if [ "$VERSION" = "LATEST" ]; then
    CACHEBUST=$(git ls-remote https://github.com/maproulette/maproulette2.git | grep HEAD | cut -f 1)
fi

echo "Building container image for MapRoulette API Version: $IMAGE_TAG, Repo: ${git[1]}"
docker build \
    --pull \
    -t maproulette/maproulette-api:"${IMAGE_TAG}" \
    --build-arg VERSION="${VERSION}" \
    --build-arg GIT="${git[1]}" \
    --build-arg CACHEBUST="${CACHEBUST}" \
    .
