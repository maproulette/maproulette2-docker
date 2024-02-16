ARG TEMURIN_JDK_TAG=11
FROM docker.io/library/eclipse-temurin:${TEMURIN_JDK_TAG} as builder

ARG SBT_VERSION=1.9.7
ARG CACHEBUST=1
ARG GIT="maproulette/maproulette-backend"
ARG VERSION="LATEST"

WORKDIR /working

# This is based on mozilla docker-sbt https://github.com/mozilla/docker-sbt/blob/main/Dockerfile
# Install sbt
RUN \
  curl -L -o sbt-$SBT_VERSION.deb https://repo.scala-sbt.org/scalasbt/debian/sbt-$SBT_VERSION.deb && \
  dpkg -i sbt-$SBT_VERSION.deb && \
  rm sbt-$SBT_VERSION.deb && \
  apt-get update && \
  apt-get install --no-install-recommends -y git sbt unzip && \
  sbt sbtVersion

RUN \
    echo "${GIT}" && \
    echo "${CACHEBUST}" && \
    echo "${VERSION}" && \
    if [ "${VERSION}" = "LATEST" ]; then \
        git clone --depth 1 https://github.com/${GIT}.git /maproulette-api ; \
    else \
        git clone --depth 1 --branch ${VERSION} https://github.com/${GIT}.git /maproulette-api ; \
    fi

WORKDIR /maproulette-api
RUN \
    echo "\n\nBUILDING API VERSION=${VERSION} COMMIT=$(git rev-parse HEAD)\n\n" && \
    sbt evicted && \
    sbt clean compile dist && \
    unzip -d / target/universal/MapRouletteAPI.zip

FROM docker.io/library/eclipse-temurin:${TEMURIN_JDK_TAG}

# Runtime image needs to have the most up-to-date patches
RUN \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y && \
    rm -rf /var/lib/apt/lists/*
RUN \
    groupadd -g 1000 maproulette && \
    useradd --uid 1000 --gid 1000 --groups 0 --create-home --home-dir /MapRouletteAPI maproulette && \
    chmod 0775 /MapRouletteAPI && \
    chown -R 1000:0 /MapRouletteAPI

COPY --from=builder --chown=1000:0 /MapRouletteAPI /MapRouletteAPI
USER maproulette
WORKDIR /MapRouletteAPI

COPY --chown=1000:0 setupServer.sh /MapRouletteAPI/setupServer.sh
COPY --chown=1000:0 application-overrides.conf /MapRouletteAPI/conf/application-overrides.conf

ENTRYPOINT ["./setupServer.sh"]
