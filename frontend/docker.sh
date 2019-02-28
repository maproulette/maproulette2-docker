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

echo "Stopping and removing maproulette frontend container"
RUNNING=$(docker inspect --format="{{ .State.Running }}" maproulette-frontend 2> /dev/null)
if [[ $? -eq 0 ]]; then
  docker stop maproulette-frontend || true && docker rm maproulette-frontend || true
fi

echo "Starting maproulette frontend container"
docker run -t --privileged -d -p 3000:80 \
	--name maproulette-frontend \
	--link maproulette-api:api \
	maproulette/maproulette-frontend:${VERSION}

