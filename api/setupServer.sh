#!/bin/bash

set -exu

APIHOST=${APIHOST:-maproulette.org}

# The java process creates RUNNING_PID and it must not exist before attempting to start java.
# Delete the file just in case the process died and is restarting.
rm -f RUNNING_PID

/MapRouletteAPI/bin/maprouletteapi \
	-Dhttp.port=9000 \
	-DAPI_HOST="${APIHOST}" \
	-Dconfig.resource=docker.conf
