#!/bin/bash

frontend=false
frontendRelease=LATEST
frontendGit="git:osmlab/maproulette3"
api=false
apiRelease=LATEST
apiGit="git:maproulette/maproulette2"
wipeDB=false
dbPort=""
apiHost="maproulette.org"

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
            if [[ $2 =~ - ]]; then
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
        --APIHost)
            apiHost=$2
            shift
        ;;
        *)
            break
        ;;
    esac
    shift
done

echo "API: $api $apiRelease $apiGit"
echo "FRONTEND: $frontend $frontendRelease $frontendGit"
if [[ "$api" = true ]]; then
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
    echo "deploying api..."
    ./backend/docker.sh $apiRelease $apiGit $apiHost
    sleep 10
fi
if [[ "$frontend" = true ]]; then
    echo "deploying frontend..."
    ./frontend/docker.sh $frontendRelease $frontendGit $api
fi
