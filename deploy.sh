#!/bin/bash

set -exuo pipefail

# Print usage information if -h or --help flags are used
if [[ $1 == "-h" ]] || [[ $1 == "--help" ]]; then
    set +x
    echo "Usage: ./deploy.sh [OPTION]..."
    echo "Automated script for deploying the MapRoulette application with frontend, API, and PostGIS database."
    echo ""
    echo "Options:"
    echo "  -f, --frontend       Optional. Deploy the frontend. Default: false."
    echo "                       Optionally specify [frontendRelease] and [frontendGit]."
    echo "                       [frontendRelease] can be a git branch, tag, or commit id. Default: LATEST."
    echo "                       [frontendGit] is the Git location for the frontend. Default: git:maproulette/maproulette3."
    echo "  -a, --api            Optional. Deploy the API. Default: false."
    echo "                       Optionally specify [apiRelease] and [apiGit]."
    echo "                       [apiRelease] can be a git branch, tag, or commit id. Default: LATEST."
    echo "                       [apiGit] is the Git location for the API. Default: git:maproulette/maproulette-backend."
    echo "  --dbPort             Optional. Specify the database port for the docker postgis container. Default: 127.0.0.1:5432."
    echo "  --wipeDB             Optional. Wipe the Docker database. Default: false."
    echo "  --dbExternal         Optional. Specify if the database is external. Default: false."
    echo "  --buildOnly          Optional. Specify if only build the Docker images without deploying them. Default: false."
    echo "  --useHostNetwork     Optional. Use host network for Docker. Default: false."
    echo "  -h, --help           Display this help and exit."
    exit 0
fi

# If there is a conf.sh, include it to override any of the below variables.
# Note that any commandline overrides will take precedence.
if [ -f "conf.sh" ]; then
    echo "Using variables from conf.sh"
    # shellcheck source=/dev/null
    source conf.sh
fi


# Whether to deploy the frontend
frontend=${frontend:-false}

# What release of the frontend to deploy
frontendRelease=${frontendRelease:-LATEST}

# The Git location for the frontend
frontendGit=${frontendGit:-"git:maproulette/maproulette3"}

# Whether to deploy the API
api=${api:-false}

# The API repository's git branch or tag used for the release.
apiRelease=${apiRelease:-LATEST}

# The git location for the API
apiGit=${apiGit:-"git:maproulette/maproulette-backend"}

# Whether the docker containers should use the host network
useHostNetwork=${useHostNetwork:-false}

# Whether to wipe the docker database, start clean
wipeDB=${wipeDB:-false}

# Host port to expose the postgis database container. By default bind to localhost:5432 so that pgadmin is able to connect to the database via an ssh tunnel.
dbPort=${dbPort:-"127.0.0.1:5432"}

# Whether the database being used is external or not. If it is external than won't link and build the database images
dbExternal=${dbExternal:-false}

# Whether to just build the docker images and not deploy them
buildOnly=${buildOnly:-false}

# Allow unset varaibles to be used while setting arguments
set +u
while true; do
    case "$1" in
        -f | --frontend)
            # Parse the --frontend arguments. The optional parameters, frontendRelease and frontendGit, are unordered (and optional!).
            # The frontendGit must start with 'git' (also, any frontendRelease branch with 'git' as the prefix cannot be used).
            #
            # For example the input could be:
            # --frontend
            # --frontend [frontendRelease]
            # --frontend [frontendRelease] [frontendGit]
            # --frontend [frontendGit]
            # --frontend [frontendGit] [frontendRelease]
            frontend=true
            while true; do
                # If '--frontend' was provided and a next '--' option was found or no remaining options, means we're done.
                if [[ "$2" =~ ^- ]] || [ -z $2 ]; then
                    break
                fi
                if [[ "$2" =~ ^git ]]; then
                    frontendGit="$2"
                    shift
                    continue
                else
                    frontendRelease="$2"
                    shift
                    continue
                fi
                break
            done
        ;;
        -a | --api)
            # Parse the --api arguments. The optional parameters, apiRelease and apiGit, are unordered (and optional!).
            # The apiGit must start with 'git' (also, any apiRelease branch with 'git' as the prefix cannot be used).
            #
            # For example the input could be:
            # --api
            # --api [apiRelease]
            # --api [apiRelease] [apiGit]
            # --api [apiGit]
            # --api [apiGit] [apiRelease]
            api=true
            while true; do
                # If '--api' was provided and a next '--' option was found or no remaining options, means we're done.
                if [[ "$2" =~ ^- ]] || [ -z $2 ]; then
                    break
                fi
                if [[ "$2" =~ ^git ]]; then
                    apiGit="$2"
                    shift
                    continue
                else
                    apiRelease="$2"
                    shift
                    continue
                fi
                break
            done
        ;;
        --useHostNetwork)
            useHostNetwork=true
        ;;
        --dbPort)
            dbPort="$2"
            shift
        ;;
        --wipeDB)
            wipeDB=true
        ;;
        --dbExternal)
            dbExternal=true
        ;;
        --buildOnly)
            buildOnly=true
        ;;
        *)
            break
        ;;
    esac
    shift
done
set -u

export USE_HOST_NETWORK="$useHostNetwork"

echo "Building MR Network"
docker network create --driver bridge mrnet || true
echo "API: $api $apiRelease $apiGit"
echo "FRONTEND: $frontend $frontendRelease $frontendGit"
if [[ "$api" = true ]]; then
    if [[ "$dbExternal" != true ]]; then
        echo "Deploying mr-postgis database container..."

        # If wipeDB is true and the mr-postgis container exists (running or stopped), then stop and remove the container
        if [[ "$wipeDB" == true && "$(docker ps -qa -f name=mr-postgis)" ]]; then
            echo "Removing mr-postgis container"
            docker stop mr-postgis
            docker rm mr-postgis
        fi

        # If the container named mr-postgis exists (running or stopped), then start it
        if [ "$(docker ps -qa -f name=mr-postgis)" ]; then
            echo "Starting the existing mr-postgis container"
            # NOTE: Starting an already-running container is not an error
            docker start mr-postgis
        else
            # The mr-postgis container does not exist. Create and run it.
            echo "Running new mr-postgis container"
            docker run \
                -d \
                -p "$dbPort":5432 \
                --name mr-postgis \
                --network mrnet \
                --restart unless-stopped \
                --shm-size=512MB \
                -e POSTGRES_DB=mrdata \
                -e POSTGRES_USER=mrdbuser \
                -e POSTGRES_PASSWORD=mrdbpass \
                --volume "$(pwd)/postgres-data":/var/lib/postgresql/data \
                postgis/postgis:11-2.5
        fi
    fi

    echo "Building api docker image..."
    ./api/docker.sh "$apiRelease" "$apiGit"
fi

if [[ "$frontend" = true ]]; then
    echo "Building frontend docker image..."
    ./frontend/docker.sh "$frontendRelease" "$frontendGit"
fi

# Deploy the docker images
if [[ "$api" = true && "$buildOnly" = false ]]; then
    echo "Deploying api..."
    ./api/docker-start.sh "$apiRelease"
    sleep 10
fi

if [[ "$frontend" = true && "$buildOnly" = false ]]; then
    echo "Deploying frontend..."
    ./frontend/docker-start.sh "$frontendRelease"
fi

echo "Deployment Complete!"
