ARG NODE_TAG=14-bullseye
ARG NGINX_TAG=1.23-alpine
FROM node:${NODE_TAG} as builder

ARG GIT="osmlab/maproulette3"
ARG CACHEBUST=2
ARG VERSION="LATEST"

RUN \
    apt-get update && \
    apt-get install -y jq && \
    rm -rf /var/lib/apt/lists/*

RUN \
    echo "${GIT}" && \
    echo "${CACHEBUST}" && \
    echo "${VERSION}" && \
    if [ "${VERSION}" = "LATEST" ]; then \
        git clone --depth 1 https://github.com/${GIT}.git /maproulette-frontend ; \
    else \
        git clone --depth 1 --branch ${VERSION} https://github.com/${GIT}.git /maproulette-frontend ; \
    fi
WORKDIR /maproulette-frontend

# This file is needed for the build process
ADD env.production .env.production
ADD customLayers.json ./src/customLayers.json

# Build the Maproulette Frontend
ENV NODE_OPTIONS="--max-old-space-size=8192"
RUN \
    yarn && \
    yarn run build

FROM nginx:${NGINX_TAG}

ADD nginx-config /etc/nginx/sites-enabled/maproulette
ADD nginx.conf /etc/nginx/nginx.conf
RUN \
    apk --update-cache upgrade && \
    mkdir -p /etc/nginx/sites-enabled /var/www/maproulette
COPY --from=builder /maproulette-frontend/build /var/www/maproulette

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
