#!/bin/bash
export VERSION=$1
echo "Starting maproulette api container"
docker run -t --privileged \
        -d -p 9000:9000 \
        --name maproulette-api \
        -dit --restart unless-stopped \
        --network mrnet \
        maproulette/maproulette-api:${VERSION}