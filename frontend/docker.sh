#!/bin/bash
# environment variables that can be set
if [[ -z "$VERSION" ]]; then
	VERSION=$1
fi
export VERSION=${VERSION}
git=(${2//:/ })
CACHEBUST=${VERSION}

cd frontend
if [[ "$VERSION" = "LATEST" ]]; then
    CACHEBUST=`git ls-remote https://github.com/osmlab/maproulette3.git | grep HEAD | cut -f 1`
fi
echo "Building maproulette frontend container"
docker build -t maproulette/maproulette-frontend:${VERSION} \
        --build-arg VERSION="${VERSION}" --build-arg GIT="${git[1]}" \
        --build-arg CACHEBUST=${CACHEBUST} .

