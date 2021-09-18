#!/bin/bash

set -exuo pipefail

export VERSION=$1
git=(${2//:/ })
apiHost=$3
CACHEBUST=${VERSION}

cd api
if [ "$VERSION" = "LATEST" ]; then
    CACHEBUST=$(git ls-remote https://github.com/maproulette/maproulette2.git | grep HEAD | cut -f 1)
fi

echo "Building container image for MapRoulette API Version: $VERSION, Repo: ${git[1]}, APIHost: $apiHost"
docker build -t maproulette/maproulette-api:"${VERSION}" \
    --build-arg VERSION="${VERSION}" --build-arg GIT="${git[1]}" \
    --build-arg APIHOST="${apiHost}" --build-arg CACHEBUST="${CACHEBUST}" .
