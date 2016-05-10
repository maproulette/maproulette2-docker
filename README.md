# Map Roulette 2 in Docker
Docker image for Map Roulette 2. This tool creates both a map roulette image and a postgres-postgis image. The postgis image is using [https://hub.docker.com/r/mdillon/postgis/](mdillon/postgis). A default database is created mr2_prod and the container is linked to the MapRoulette 2 container.

# Creating Instances

### Setting up Configuration

There are a couple of required properties that you will need to setup prior to running the docker.sh shell script. These settings need to be updated in the docker.conf file, look for the "CHANGE_ME" fields.

* DOCKER_USER - This is the username of the user setting up the docker images, if not supplied will default to "DEFAULT_USER"
* MAPROULETTE_DB_URL - This is the location of the database. This is set to the linked postgres docker container, so doesn't need to be explicitly set unless using a different database.
* MAPROULETTE_CONSUMER_KEY - This is the consumer key for your MapRoulette application in your openstreetmap.org account. 
* MAPROULETTE_CONSUMER_SECRET - This is the consumer secret that is found in the same MapRoulette application settings as is the consumer key. 

Other properties that are useful to know about.

* maproulette.super.key - This is the api key that can be used for any API requests and the server will assume that the person making the request is a super user. No requirement to login.
* maproulette.super.accounts - This is a comma separated list of OSM account ids that will be elevated to super user access when they login. 

### Running docker.sh

To create the MapRoulette and Postgis docker instance you just need to execute the docker.sh script. This will build the two instances and link them together. By default the Map Roulette service will start up on port 8080, if you need to change this you will need to change the port in the following places:

* Dockerfile line 13
* run_docker.sh line 26
* setupServer.sh line 14

### Deploying to Open stack

Running docker.sh will deploy the containers locally and will require the user to have VirtualBox setup correctly. Alternatively you can run deploy_openstack.sh and deploy the containers to an OpenStack environment. The most important thing that this requires is that you have your Keystone credentials sourced into your environment. Please refer to your openstack documentation for information about your keystone credentials and where to get them. Other than that you will need to edit the deploy_openstack.sh file lines 6 through 14 which contain properties for the image that you want to create for your containers. 

### Deploying to other environments

You can create your own shell scripts to deploy to various other environments as well, please refer to the docker documentation [https://docs.docker.com/machine/drivers/](here). If you do create your own scripts please don't hesistate to create a PR into this repo.

# Thanks

To [https://github.com/matthieun](matthieun) for the docker work on the original Map Roulette which I used a bit as reference.
