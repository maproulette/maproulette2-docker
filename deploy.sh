#!/bin/bash

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
        *)
            break
        ;;
    esac
    shift
done

echo "Building MR Network"
docker network create --driver bridge mrnet || true
echo "API: $api $apiRelease $apiGit"
echo "FRONTEND: $frontend $frontendRelease $frontendGit"
if [[ "$api" = true ]]; then
    if [[ "$dbExternal" != true ]]; then
        echo "deploying database..."
        if [[ "$wipeDB" == true ]]; then
            echo "Stopping and removing mr-postgis container"
            docker stop mr-postgis
            docker rm mr-postgis
        fi

        instance=$(docker ps -a | grep mdillon/postgis)
        if [[ -z "$instance" ]]; then
            echo "Building new mr-postgis container"
            docker run $dbPort \
                --name mr-postgis \
                --network mrnet \
                -e POSTGRES_DB=mrdata \
                -e POSTGRES_USER=mrdbuser \
                -e POSTGRES_PASSWORD=mrdbpass \
                -d mdillon/postgis
            sleep 10
        fi
        instance=$(docker ps | grep mdillon/postgis)
        if [[ -z "$instance" ]]; then
            echo "Restarting mr-postgis container"
            docker start mr-postgis
        fi
    fi
    echo "deploying api..."
    ./api/docker.sh $apiRelease $apiGit $apiHost
    sleep 10
fi
if [[ "$frontend" = true ]]; then
    echo "deploying frontend..."
    ./frontend/docker.sh $frontendRelease $frontendGit
fi
