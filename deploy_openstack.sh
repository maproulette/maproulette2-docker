#!/bin/bash
# This script will initialize the open stack docker-machine
# Source your keystone credentials, so that the environment variables are present, otherwise this will fail.
# See https://docs.docker.com/machine/drivers/openstack/ for more information
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
 MapRoulette2

status=$(docker-machine status MapRoulette2)
if [ "$status" != "Running" ]; then
	docker-machine start MapRoulette2
fi
docker-machine env MapRoulette2
eval "$(docker-machine env MapRoulette2)"

./run_docker.sh