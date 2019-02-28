#!/bin/bash
PORT=$1
APIHOST=$2
if [ -z "$APIHOST" ]; then
	APIHOST="maproulette.org"
fi
if [ -z "$PORT" ]; then
	PORT=9000
fi

/MapRouletteAPI/bin/maprouletteapi -Dhttp.port=$PORT -Dconfig.resource=docker.conf \
	-DAPI_HOST="${APIHOST}" \
	-Djavax.net.ssl.trustStore=/MapRouletteV2/conf/osmcacerts \
	-Djavax.net.ssl.trustStorePassword=openstreetmap
