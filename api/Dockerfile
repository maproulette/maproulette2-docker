ARG NODE_TAG=22-bullseye
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
ENV NODE_OPTIONS="--max-old-space-size=4096"
RUN \
    echo "\n\nBUILDING API VERSION=${VERSION} COMMIT=$(git rev-parse HEAD)\n\n" && \
    npm ci && \
    npm run build -w backend

FROM docker.io/library/node:${NODE_TAG}

RUN \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y && \
    apt-get install --no-install-recommends -y postgresql-client && \
    rm -rf /var/lib/apt/lists/*

RUN \
    groupadd -g 1001 maproulette && \
    useradd --uid 1001 --gid 1001 --groups 0 --create-home --home-dir /home/maproulette maproulette && \
    mkdir -p /app && \
    chown -R 1001:0 /app

USER maproulette
WORKDIR /app

COPY --from=builder --chown=1001:0 /maproulette/package.json /maproulette/package-lock.json /app/
COPY --from=builder --chown=1001:0 /maproulette/shared /app/shared
COPY --from=builder --chown=1001:0 /maproulette/backend/package.json /app/backend/package.json
COPY --from=builder --chown=1001:0 /maproulette/backend/dist /app/backend/dist
COPY --from=builder --chown=1001:0 /maproulette/backend/drizzle /app/backend/drizzle
COPY --from=builder --chown=1001:0 /maproulette/backend/drizzle.config.ts /app/backend/drizzle.config.ts
COPY --from=builder --chown=1001:0 /maproulette/node_modules /app/node_modules
COPY --from=builder --chown=1001:0 /maproulette/backend/node_modules /app/backend/node_modules

COPY --chown=1001:0 setupServer.sh /app/backend/setupServer.sh

WORKDIR /app/backend

ENV PORT=9000
EXPOSE 9000

ENTRYPOINT ["./setupServer.sh"]
