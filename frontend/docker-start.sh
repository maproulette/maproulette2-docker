#!/bin/bash
if [[ -z "$VERSION" ]]; then
	VERSION=$1
fi
export VERSION=${VERSION}
echo "Stopping and removing maproulette frontend container"
RUNNING=$(docker inspect --format="{{ .State.Running }}" maproulette-frontend 2> /dev/null)
if [[ $? -eq 0 ]]; then
  docker stop maproulette-frontend || true && docker rm maproulette-frontend || true
fi
echo "Starting maproulette frontend container"
docker run -t --privileged -d -p 3000:80 \
	--name maproulette-frontend \
    -dit --restart unless-stopped \
    --network mrnet \
	maproulette/maproulette-frontend:${VERSION}