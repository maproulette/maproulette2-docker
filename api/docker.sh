#!/bin/bash
export VERSION=$1
git=(${2//:/ })
apiHost=$3
CACHEBUST=${VERSION}

cd api
if [[ "$VERSION" = "LATEST" ]]; then
    CACHEBUST=`git ls-remote https://github.com/maproulette/maproulette2.git | grep HEAD | cut -f 1`
fi
echo "Building container for MapRoulette API Version: $VERSION, Repo: ${git[1]}, APIHost: $apiHost"
docker build -t maproulette/maproulette-api:${VERSION} \
    --build-arg VERSION="${VERSION}" --build-arg GIT="${git[1]}" \
    --build-arg APIHOST="${apiHost}" --build-arg CACHEBUST=${CACHEBUST} .

echo "Stopping and removing maproulette api container"
RUNNING=$(docker inspect --format="{{ .State.Running }}" maproulette-api 2> /dev/null)
if [[ $? -eq 0 ]]; then
  docker stop maproulette-api || true && docker rm maproulette-api || true
fi

echo "Starting maproulette api container"
docker run -t --privileged \
        -d -p 9000:9000 \
        --name maproulette-api \
        -dit --restart unless-stopped \
        --network mrnet \
        maproulette/maproulette-api:${VERSION}
