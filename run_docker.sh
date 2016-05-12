#!/bin/bash
# environment variables that can be set
if [ -z "$DOCKER_VERSION" ]; then
	DOCKER_VERSION=1.0.0	
fi
if [ -z "$DOCKER_USER" ]; then
	DOCKER_USER="DEFAULT_USER"
fi
#This line gets the latest commit hash to use as the cachebust, when it changes the 
#it will break the cache on the line just before we pull the code. So that it won't use
#the cache and instead will pull the latest and repackage
export CACHEBUST=`git ls-remote https://github.com/maproulette/maproulette2.git | grep HEAD | cut -f 1`
docker build -t $DOCKER_USER/maproulette2:$DOCKER_VERSION --build-arg CACHEBUST=$CACHEBUST .

# Run it locally. Optional
if [ "$locally" == true ]; then
	echo "Removing docker images locally"
	docker rm -f `docker ps --no-trunc -aq`
fi

if [ "$rpg" == true ]; then
	echo "Stopping and removing mr2-postgis container"
	docker stop mr2-postgis
	docker rm mr2-postgis
fi

instanceRunning=$(docker ps | grep mdillon/postgis)
if [ -z "$instanceRunning" ]; then
	echo "Restarting mr2-postgis container"
	docker run --name mr2-postgis \
		-e POSTGRES_DB=mr2_prod \
		-e POSTGRES_USER=mr2dbuser \
		-e POSTGRES_PASSWORD=mr2dbpassword \
		-d mdillon/postgis
	sleep 10
fi

echo "Stopping and removing maproulette2 container"
docker stop maproulette2
docker rm maproulette2
echo "Restarting maproulette2 container"
docker run -t --privileged -d -p 80:80 \
	--name maproulette2 \
	--link mr2-postgis:db \
	$DOCKER_USER/maproulette2:$DOCKER_VERSION

docker ps