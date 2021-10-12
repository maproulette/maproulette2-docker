# MapRoulette in Docker
Docker image and deployment scripts for Map Roulette api, database and fronted. This tool creates a MapRoulette backend image as well as a postgres-postgis image. The postgis image is using [https://hub.docker.com/r/mdillon/postgis/](mdillon/postgis). A default database is created mrdata and the container is linked to the MapRoulette API container. This can be used for deploying the entire stack or any of the 3 components individually. The frontend is deployed with an nginx docker image and the static build files from the MapRoulette frontend.

# Deployment

### Setting up Configuration

##### API
There are a couple of required properties that you will need to setup prior to running `deploy.sh`.

The main application configuration is located within the [maproulette2 repository as application.conf](https://github.com/maproulette/maproulette2/blob/dev/conf/application.conf), and the below will override the originals.

To avoid accidentally checking in private keys, the `api/application-overrides.template.conf` file must be copied as `api/application-overrides.conf`, and at a minimum these settings need to be updated, look for the "CHANGE_ME" fields.

* **db.default.url** - This is the location of the database. This is set to the linked postgres docker container, so doesn't need to be explicitly set unless using a different database. If you are not deploying the Postgres database using Docker then update this field with the connection string to your external database
* **osm.consumerKey** - This is the consumer key for your MapRoulette application in your openstreetmap.org account.
* **osm.consumerSecret** - This is the consumer secret that is found in the same MapRoulette application settings as is the consumer key.
* **maproulette.super.key** - This is the api key that can be used for any API requests and the server will assume that the person making the request is a super user. No requirement to login.
* **maproulette.super.accounts** - This is a comma separated list of OSM account ids that will be elevated to super user access when they login.
* **maproulette.bootstrap** - Set this to `true` when you build a new MapRoulette API with a new database.

##### Frontend
The frontend requires certain properties to be updated as well. The main configuration is located within the [maproulette3 repository as .env](https://github.com/osmlab/maproulette3/blob/main/.env), and the below will override the originals.

To avoid accidentally checking in private data, the `frontend/env.template.production` file must be copied as `frontend/env.production`, and updated as necessary.

The env.template.production assume that it is pointing to an instance of the MapRoulette backend that has been deployed by docker. So if you do deploy the backend using the deploy script (docker) then you won't need to change these properties.

* **REACT_APP_BASE_PATH** - This is the root path for the MapRoulette frontend App. Which by default is "/" and wouldn't ordinarily need to be changed.
* **REACT_APP_URL** - This is the root url for the MapRoulette frontend App. By default it is localhost:3000, the reason for this is that it is generally advisable to front these services with a http server like nginx or Apache webserver. And those web servers would then just proxy requests on port 80 to port 3000. But if you don't need certain features you can change this to port 80 instead and not have it fronted by a web server.
* **REACT_APP_MAP_ROULETTE_SERVER_URL** - This is the root server url for the MapRoulette backend. By default the MapRoulette backend will startup on port 9000, but if you are pointing to an instance that has started up on a different port you can change that here.

### Running deploy.sh

The deploy script can deploy the 3 services that are required for a complete MapRoulette setup. The database, the backend and the frontend. Any combination of the 3 can be deployed as needed using the deploy.sh script. The primary script takes the following parameters:

- **-f | --frontend [RELEASE_VERSION] [GIT]** - Deploys the frontend using docker. If the RELEASE_VERSION is not supplied it will set it to `LATEST` and will pull the latest code from github. If you just want the latest then use "LATEST". If GIT is not supplied then it will use the default `git:osmlab/maproulette3`. The GIT value is optional had has the form `git:<GIT_ORGANIZATION>/<GIT_REPO>`. By using the git option you can deploy maproulette from any repo. Most comon usage would be if you have forked MapRoulette and have changes that may not be ready to be published to the public repo.
- **-a | --api [RELEASE_VERSION] [GIT]** - Deploys the backend using docker. If the RELEASE_VERSION is not supplied it will set it to `LATEST` and will pull the latest code from github. If you just want the latest then use `LATEST`. Important to note the frontend and backend have different release cycles and different versions. Some frontends may be incompatible with some frontend versions. For GIT options see above. Default value is `git:maproulette/maproulette2`.
- **--dbPort [PORT]** - This option allows the deployed postgres database to be accessible by some port. The port is required when using this option.

Other deploy options

- **--wipeDB** - This option will wipeout the database image and recreate from scratch. Be careful when using this option as it will wipe out any data in your database. So generally it is a good idea to backup the database prior to doing this.
- **--apiHost [API URL]** - This option is for the Swagger UI and defines the URL that the API is being deployed on.

##### Examples

Deploy only the frontend:

`./deploy.sh -f 3.2.1`

Deploy only the api/backend

`./deploy.sh -a 3.4.0`

Deploy everything

`./deploy.sh -f 3.2.1 -a 3.4.0`

Deploy the backend from a specific git repo using database port 5301

`./deploy.sh -a customrepo/maproulette2.git --dbPort 5301`

The ordering of your flags does not matter.

### FAQ

**I want to connect to my own database, how do I do that?**

This is fortunately very easy to accomplish. In the `api/application-overrides.conf` file just modify the `db.default.url` property to your database.

**Wait, this is for development, the server is on `localhost` it doesn't work, what now?**

In this case all you need to do is set the server host to `host.docker.internal` and the docker container will know how to communicate with this host. Ie. your database on the localhost.

**I want to only deploy the frontend but it is failing, why?**

If the backend and frontend are deployed it will link the containers together so that they nginx configuration can route any connections to the api container correctly. However if you are only deploying the frontend container then the nginx configuration for that routing will be incorrect. This will cause failure in the creation of the frontend container. To fix this you need to modify the `nginx-config` file by updating the upstream api section to look like follows:
```
upstream api {
    server <API URL>:<API PORT>
}
```
