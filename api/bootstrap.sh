#!/bin/bash

echo "bootstrap"

service ssh restart

cd /MapRouletteAPI
# Delete any RUNNING_PID file on restart
rm RUNNING_PID || true
./setupServer.sh > setupServer.log 2>&1

while true; do sleep 1000; done
