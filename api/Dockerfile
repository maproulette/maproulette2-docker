FROM adoptopenjdk/openjdk8:jdk8u212-b03 

RUN export TERM=xterm

# Add the User
RUN adduser -system --gid 0 maproulette

# Apt-Get for basic packages
RUN apt-get update && apt-get upgrade -y && apt-get install -y apt-transport-https
RUN echo "deb https://dl.bintray.com/sbt/debian /" | tee -a /etc/apt/sources.list.d/sbt.list
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 642AC823
RUN apt-get update && apt-get upgrade -y && apt-get install -y scala sbt unzip wget git openssh-server jq g++ build-essential
EXPOSE 80

ARG GIT="maproulette/maproulette2"
RUN echo ${GIT}
ARG CACHEBUST=1
RUN echo $CACHEBUST
# Download Maproulette V2
RUN git clone https://github.com/${GIT}.git /maproulette-api
RUN chmod 777 /maproulette-api
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

# Retrieve OSM & Mapillary Certificates
WORKDIR /
RUN openssl s_client -showcerts -connect "www.openstreetmap.org:443" -servername www.openstreetmap.org </dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > osm.pem
RUN openssl s_client -showcerts -connect "a.mapillary.com:443" -servername a.mapillary.com </dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > mapillary.pem
RUN keytool -importcert -noprompt -trustcacerts -alias a.mapillary.com -file mapillary.pem -keystore osmcacerts -storepass openstreetmap
RUN keytool -importcert -noprompt -trustcacerts -alias www.openstreetmap.org -file osm.pem -keystore osmcacerts -storepass openstreetmap

# Bootstrap commands
ADD bootstrap.sh /etc/bootstrap.sh
ADD setupServer.sh /MapRouletteAPI/setupServer.sh
ADD docker.conf	/MapRouletteAPI/conf/docker.conf
RUN chmod 777 /etc/bootstrap.sh
RUN chmod 777 /MapRouletteAPI/setupServer.sh
WORKDIR /MapRouletteAPI
# Move the truststore to the correct location
RUN mv /osmcacerts conf/

ARG APIHOST="maproulette.org"
ENV APIHOST=${APIHOST}
ENV PORT=9000

ENTRYPOINT ["/etc/bootstrap.sh"]
