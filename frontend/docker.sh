#!/bin/bash

set -exuo pipefail

# The VERSION can be set with an environment variable. If it's not set, use $1
export VERSION=${VERSION:-$1}
git=(${2//:/ })
CACHEBUST=${VERSION}

cd frontend
if [ "$VERSION" = "LATEST" ]; then
    CACHEBUST=$(git ls-remote https://github.com/osmlab/maproulette3.git | grep HEAD | cut -f 1)
fi

echo "Building container image for MapRoulette frontend Version: $VERSION, Repo: ${git[1]}"
docker build -t maproulette/maproulette-frontend:"${VERSION}" \
        --build-arg VERSION="${VERSION}" --build-arg GIT="${git[1]}" \
        --build-arg CACHEBUST="${CACHEBUST}" .
