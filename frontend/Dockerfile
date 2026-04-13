ARG NODE_TAG=22-bullseye
ARG NGINX_TAG=1.25-alpine
FROM docker.io/library/node:${NODE_TAG} AS builder

ARG GIT="maproulette/maproulette4"
ARG CACHEBUST=1
ARG VERSION="LATEST"

RUN \
    apt-get update && \
    apt-get install --no-install-recommends -y git && \
    rm -rf /var/lib/apt/lists/*

RUN \
    echo "${GIT}" && \
    echo "${CACHEBUST}" && \
    echo "${VERSION}" && \
    if [ "${VERSION}" = "LATEST" ]; then \
        git clone --depth 1 https://github.com/${GIT}.git /maproulette ; \
    else \
        git clone --depth 1 --branch ${VERSION} https://github.com/${GIT}.git /maproulette ; \
    fi

WORKDIR /maproulette

# Vite inlines VITE_* env vars at build time, so the .env must exist before
# `npm run build`. It's placed at the monorepo root to match SETUP.md.
COPY .env /maproulette/.env

ENV NODE_OPTIONS="--max-old-space-size=8192"
RUN \
    npm ci && \
    npm run build -w frontend

FROM docker.io/library/nginx:${NGINX_TAG}

COPY nginx-config /etc/nginx/sites-enabled/maproulette
COPY nginx.conf /etc/nginx/nginx.conf
RUN \
    apk --update-cache upgrade && \
    mkdir -p /etc/nginx/sites-enabled /var/www/maproulette
COPY --from=builder /maproulette/frontend/dist /var/www/maproulette

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
