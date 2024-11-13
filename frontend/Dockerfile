ARG NODE_TAG=18-bullseye
ARG NGINX_TAG=1.25-alpine
FROM docker.io/library/node:${NODE_TAG} as builder

ARG GIT="maproulette/maproulette3"
ARG CACHEBUST=2
ARG VERSION="LATEST"

RUN \
    apt-get update && \
    apt-get install --no-install-recommends -y \
        jq \
        python2 \
    && \
    ln -sf /usr/bin/python2 /usr/bin/python && \
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
COPY env.production .env.local
COPY customLayers.json ./src/customLayers.json

# Build the Maproulette Frontend
ENV NODE_OPTIONS="--max-old-space-size=8192"
RUN \
    yarn --network-timeout 100000 && \
    yarn --network-timeout 100000 run build

FROM docker.io/library/nginx:${NGINX_TAG}

COPY nginx-config /etc/nginx/sites-enabled/maproulette
COPY nginx.conf /etc/nginx/nginx.conf
RUN \
    apk --update-cache upgrade && \
    mkdir -p /etc/nginx/sites-enabled /var/www/maproulette
COPY --from=builder /maproulette-frontend/dist /var/www/maproulette

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
