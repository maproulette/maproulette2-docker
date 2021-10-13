#!/bin/sh
#
# The variables below are sourced within the 'deploy.sh' script.
# Override as needed for a deployment.
# Note that any commandline overrides will take precedence.
#

# Whether to deploy the frontend
# frontend=false

# What release of the frontend to deploy
# frontendRelease=LATEST

# The Git location for the frontend
# frontendGit="git:osmlab/maproulette3"

# Whether to deploy the API
# api=false

# What release of the API to deploy
# apiRelease=LATEST

# The Git location for the API
# apiGit="git:maproulette/maproulette2"

# Whether to wipe the docker database, start clean
# wipeDB=false

# Host port to expose the postgis database container. By default bind to localhost:5432 so that pgadmin is able to connect to the database via an ssh tunnel.
# dbPort="127.0.0.1:5432"

# What host the API is on, used for Swagger
# apiHost="maproulette.org"

# Whether the database being used is external or not. If it is external than won't link and build the database images
# dbExternal=false

# Whether to just build the docker images and not deploy them
# buildOnly=false
