# Map Roulette 2 in Docker
Docker image for Map Roulette 2. This tool creates both a map roulette image and a postgres-postgis image. The postgis image is using [https://hub.docker.com/r/mdillon/postgis/](mdillon/postgis). A default database is created mr2_prod and the container is linked to the MapRoulette 2 container.

# Creating Instances

### Setting up Configuration

There are a couple of required properties that you will need to setup prior to running the docker.sh shell script. These settings can be set as system properties:

1. MAPROULETTE_DB_URL - This is the location of the database. You shouldn't need to set this as the URL is automatically set for you by the docker.conf file. 
2. MAPROULETTE_CONSUMER_KEY - This is the consumer key for your MapRoulette application in your openstreetmap.org account. This can be set by setting the value as a system property, or alternatively it can be modified in the docker.conf file, by modifying the variable osm.consumerKey
3. MAPROULETTE_CONSUMER_SECRET - This is the consumer secret that is found in the same MapRoulette application settings as is the consumer key. Like all the above variables they can be set through a system property or alternatively modified in the docker.conf file.

The settings below are useful properties that can be modified in the docker.conf

* maproulette.super.key - This is the api key that can be used for any API requests and the server will assume that the person making the request is a super user. No requirement to login.
* maproulette.super.accounts - This is a comma separated list of OSM account ids that will be elevated to super user access when they login. 

### Running docker.sh

To create the MapRoulette and Postgis docker instance you just need to execute the docker.sh script. This will build the two instances and link them together. By default the Map Roulette service will start up on port 8080, however this is configurable simply by passing in the port number to the docker script. eg. `docker.sh 9000`

# Thanks

To [https://github.com/matthieun](matthieun) for the docker work on the original Map Roulette which I used a bit as reference.
