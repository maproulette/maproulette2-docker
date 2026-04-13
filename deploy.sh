#!/bin/bash

set -exuo pipefail

if [[ ${1:-} == "-h" ]] || [[ ${1:-} == "--help" ]]; then
    set +x
    echo "Usage: ./deploy.sh [OPTION]..."
    echo "Build and deploy the MapRoulette monorepo (frontend, API, and PostGIS database)."
    echo ""
    echo "Both the API and frontend are built from the same monorepo clone, so they share"
    echo "the --release and --git flags below."
    echo ""
    echo "Options:"
    echo "  -f, --frontend       Deploy the frontend container. Default: false."
    echo "  -a, --api            Deploy the API container. Default: false."
    echo "  -r, --release VER    Git branch, tag, or commit id to build. Default: LATEST."
    echo "  -g, --git ORG/REPO   Source repository. Default: maproulette/maproulette4."
    echo "  --dbPort PORT        Host port for the postgis container. Default: 127.0.0.1:5432."
    echo "  --wipeDB             Stop and recreate the postgis container. Default: false."
    echo "  --dbExternal         The database is external — don't manage a postgis container."
    echo "  --buildOnly          Build images but do not start containers. Default: false."
    echo "  --useHostNetwork     Use host networking for all containers. Default: false."
    echo "  -h, --help           Display this help and exit."
    exit 0
fi

# If there is a conf.sh, include it to override any of the below variables.
# Commandline overrides take precedence.
if [ -f "conf.sh" ]; then
    echo "Using variables from conf.sh"
    # shellcheck source=/dev/null
    source conf.sh
fi

frontend=${frontend:-false}
api=${api:-false}

# A single release + git pair is used for both the api and frontend builds —
# they live in the same monorepo now.
release=${release:-LATEST}
git=${git:-"git:maproulette/maproulette4"}

useHostNetwork=${useHostNetwork:-false}
wipeDB=${wipeDB:-false}
dbPort=${dbPort:-"127.0.0.1:5432"}
dbExternal=${dbExternal:-false}
buildOnly=${buildOnly:-false}

set +u
while true; do
    case "$1" in
        -f | --frontend)
            frontend=true
        ;;
        -a | --api)
            api=true
        ;;
        -r | --release)
            release="$2"
            shift
        ;;
        -g | --git)
            if [[ "$2" =~ ^git ]]; then
                git="$2"
            else
                git="git:$2"
            fi
            shift
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

if [[ "$api" != true && "$frontend" != true ]]; then
    echo "Nothing to do — pass --api and/or --frontend." >&2
    exit 1
fi

if [ ! -f ".env" ]; then
    echo "File .env does not exist!" >&2
    echo "Copy .env.template to .env at the repo root and fill in the values." >&2
    exit 1
fi

echo "Building MR Network"
docker network create --driver bridge mrnet || true
echo "RELEASE: $release  GIT: $git"
echo "API: $api  FRONTEND: $frontend"

if [[ "$api" = true ]]; then
    if [[ "$dbExternal" != true ]]; then
        echo "Deploying mr-postgis database container..."

        if [[ "$wipeDB" == true && "$(docker ps -qa -f name=mr-postgis)" ]]; then
            echo "Removing mr-postgis container"
            docker stop mr-postgis
            docker rm mr-postgis
        fi

        if [ "$(docker ps -qa -f name=mr-postgis)" ]; then
            echo "Starting the existing mr-postgis container"
            docker start mr-postgis
        else
            echo "Running new mr-postgis container"
            mkdir -p postgres-data
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
                postgis/postgis:17-3.5
        fi
    fi

    echo "Building api docker image..."
    ./api/docker.sh "$release" "$git"
fi

if [[ "$frontend" = true ]]; then
    echo "Building frontend docker image..."
    ./frontend/docker.sh "$release" "$git"
fi

if [[ "$api" = true && "$buildOnly" = false ]]; then
    echo "Deploying api..."
    ./api/docker-start.sh "$release"
    sleep 10
fi

if [[ "$frontend" = true && "$buildOnly" = false ]]; then
    echo "Deploying frontend..."
    ./frontend/docker-start.sh "$release"
fi

echo "Deployment Complete!"
