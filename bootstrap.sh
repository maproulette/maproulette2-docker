#!/bin/bash

echo "bootstrap"

service ssh restart

cd /MapRouletteV2

./setupServer.sh > setupServer.log 2>&1

while true; do sleep 1000; done
