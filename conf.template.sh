#!/bin/sh
#
# The variables below are sourced within the 'deploy.sh' script.
# Override as needed for a deployment.
# Commandline overrides take precedence.
#

# Whether to deploy the frontend
# frontend=false

# Whether to deploy the API
# api=false

# The release (branch, tag, or commit) to build. Applies to both frontend and
# api since they live in the same monorepo.
# release=LATEST

# The git location of the monorepo.
# git="git:maproulette/maproulette4"

# Whether the docker containers should use the host network
# useHostNetwork=false

# Whether to wipe the docker database, start clean
# wipeDB=false

# Host port to expose the postgis database container. By default bind to
# localhost:5432 so that pgadmin is able to connect to the database via an
# ssh tunnel.
# dbPort="127.0.0.1:5432"

# Whether the database being used is external. When true, deploy.sh won't
# manage a postgis container.
# dbExternal=false

# Whether to just build the docker images and not deploy them
# buildOnly=false
