#!/bin/bash

set -exuo pipefail

# Whether to deploy the frontend
frontend=false
# What release of the frontend to deploy
frontendRelease=LATEST
# The Git location for the frontend
frontendGit="git:osmlab/maproulette3"
# Whether to deploy the API
api=false
# What release of the API to deploy
apiRelease=LATEST
# The Git location for the API
apiGit="git:maproulette/maproulette2"
# Whether to wipe the docker database, start clean
wipeDB=false
# What port to expose the docker database on, by default will not expose it
dbPort=""
# What host the API is on, used for Swagger
apiHost="maproulette.org"
# Whether the database being used is external or not. If it is external than won't link and build the database images
dbExternal=false
# Whether to just build the docker images and not deploy them
buildOnly=false

# Allow unset varaibles to be used while setting arguments
set +u
while true; do
    case "$1" in
        -f | --frontend)
            frontend=true
            if [[ "$2" =~ ^- ]]; then
                shift
                continue
            fi
            while true; do
                if [[ "$2" =~ ^git ]]; then
                    frontendGit="$2"
                    shift
                    continue
                elif [[ "$2" = "LATEST" ]] || [[ "$2" =~ ^[0-9v] ]]; then
                    frontendRelease="$2"
                    shift
                    continue
                fi
                break
            done
        ;;
        -a | --api)
            api=true
            if [[ $2 =~ ^- ]]; then
                shift
                continue
            fi
            while true; do
                if [[ "$2" =~ ^git ]]; then
                    apiGit="$2"
                    shift
                    continue
                elif [[ "$2" = "LATEST" ]] || [[ "$2" =~ ^[0-9v] ]]; then
                    apiRelease="$2"
                    shift
                    continue
                fi
                break
            done
        ;;
        --dbPort)
            dbPort="-p 5432:$2"
            shift
        ;;
        --wipeDB)
            wipeDB=true
        ;;
        --apiHost)
            apiHost=$2
            shift
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
                $dbPort \
                --name mr-postgis \
                --network mrnet \
                --restart unless-stopped \
                -e POSTGRES_DB=mrdata \
                -e POSTGRES_USER=mrdbuser \
                -e POSTGRES_PASSWORD=mrdbpass \
                mdillon/postgis
        fi
    fi

    echo "Building api docker image..."
    ./api/docker.sh "$apiRelease" "$apiGit" "$apiHost"
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
