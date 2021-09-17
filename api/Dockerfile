FROM openjdk:8u302-slim

RUN export TERM=xterm

# Add the User
RUN adduser -system --gid 0 maproulette

# Apt-Get for basic packages
RUN apt-get update && apt-get upgrade -y && apt-get install -y apt-transport-https gnupg2 curl
RUN echo "deb https://repo.scala-sbt.org/scalasbt/debian all main" | tee /etc/apt/sources.list.d/sbt.list
RUN echo "deb https://repo.scala-sbt.org/scalasbt/debian /" | tee /etc/apt/sources.list.d/sbt_old.list
RUN curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" | apt-key add
RUN apt-get update && apt-get upgrade -y && apt-get install -y scala sbt unzip wget git openssh-server jq g++ build-essential

EXPOSE 80

ARG GIT="maproulette/maproulette2"
RUN echo ${GIT}
ARG CACHEBUST=1
RUN echo $CACHEBUST
# Download Maproulette V2
RUN git clone https://github.com/${GIT}.git /maproulette-api
RUN chmod 775 /maproulette-api
WORKDIR /maproulette-api
ARG VERSION="LATEST"
RUN echo $VERSION
RUN if [ "${VERSION}" != "LATEST" ]; then git checkout tags/${VERSION} ; fi

# package Maproulette V2
ARG APIHOST="maproulette.org"
RUN echo ${APIHOST}
RUN export API_HOST=${APIHOST};sbt clean compile dist
RUN unzip -d / target/universal/MapRouletteAPI.zip
WORKDIR /MapRouletteAPI

# Bootstrap commands
ADD bootstrap.sh /etc/bootstrap.sh
ADD setupServer.sh /MapRouletteAPI/setupServer.sh
ADD docker.conf	/MapRouletteAPI/conf/docker.conf
RUN chmod 775 /etc/bootstrap.sh
RUN chmod 775 /MapRouletteAPI/setupServer.sh
WORKDIR /MapRouletteAPI

# Add the OSM cert to the Java Truststore
RUN openssl s_client -showcerts -connect "www.openstreetmap.org:443" -servername www.openstreetmap.org </dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > osm.pem
RUN keytool -importcert -noprompt -trustcacerts -alias www.openstreetmap.org -file osm.pem -keystore $JAVA_HOME/jre/lib/security/cacerts -storepass changeit

ARG APIHOST="maproulette.org"
ENV APIHOST=${APIHOST}
ENV PORT=9000

ENTRYPOINT ["/etc/bootstrap.sh"]
