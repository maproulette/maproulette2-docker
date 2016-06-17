#!/bin/bash
docker-machine create --driver virtualbox default
status=$(docker-machine status default)
if [ "$status" != "Running" ]; then
	docker-machine start default
fi
docker-machine env default
eval "$(docker-machine env default)"

export rpg=false
./run_docker.sh
