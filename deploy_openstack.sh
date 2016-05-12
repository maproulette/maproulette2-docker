#!/bin/bash
# This script will initialize the open stack docker-machine
# Source your keystone credentials, so that the environment variables are present, otherwise this will fail.
# See https://docs.docker.com/machine/drivers/openstack/ for more information
INSTANCE_NAME="MapRoulette2"
if [ -n "$1" ]; then
	INSTANCE_NAME="$1"
fi
docker-machine create --driver openstack\
 --openstack-ssh-user ubuntu\
 --openstack-image-name ubuntu_15.10\
 --openstack-flavor-name m1.medium\
 --openstack-floatingip-pool [CHANGE_ME]\
 --openstack-sec-groups default\
 --openstack-keypair-name [CHANGE_ME]\
 --openstack-private-key-file [CHANGE_ME]\
 --openstack-availability-zone common\
 --openstack-net-name [CHANGE_ME]\
 $INSTANCE_NAME

status=$(docker-machine status $INSTANCE_NAME)
if [ "$status" != "Running" ]; then
	docker-machine start $INSTANCE_NAME
fi
docker-machine env $INSTANCE_NAME
eval "$(docker-machine env $INSTANCE_NAME)"

export locally=false
export rpg=false
./run_docker.sh