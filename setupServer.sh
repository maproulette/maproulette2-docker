#!/bin/bash
# If you don't set 
if [ -z "$MAPROULETTE_DB_URL" ]; then
	MAPROULETTE_DB_URL="CHANGE_ME"
fi
if [ -z "$MAPROULETTE_CONSUMER_KEY" ]; then
	MAPROULETTE_CONSUMER_KEY="CHANGE_ME"
fi
if [ -z "$MAPROULETTE_CONSUMER_SECRET" ]; then
	MAPROULETTE_CONSUMER_SECRET="CHANGE_ME"
fi	
port=$1
if [ -z "$port" ]; then
	port="8080"
fi

/maproulettev2-1.0/bin/maproulettev2 -Dhttp.port=$port -Dconfig.resource=docker.conf \
	-DDATABASE_URL=$MAPROULETTE_DB_URL -DCONSUMER_KEY=$MAPROULETTE_CONSUMER_KEY \
	-DCONSUMER_SECRET=$MAPROULETTE_CONSUMER_SECRET