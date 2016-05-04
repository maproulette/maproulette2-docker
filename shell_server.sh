#!/bin/bash

docker-machine env default
eval "$(docker-machine env default)"
docker exec -i -t maproulette2 bash