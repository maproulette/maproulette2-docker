FROM java:8-jdk

RUN export TERM=xterm

# Add the User
RUN adduser -system --gid 0 maproulette

# Apt-Get for basic packages
RUN apt-get update && apt-get upgrade -y && apt-get install -y apt-transport-https
RUN echo "deb https://dl.bintray.com/sbt/debian /" | tee -a /etc/apt/sources.list.d/sbt.list
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 642AC823
RUN apt-get update && apt-get upgrade -y && apt-get install -y scala sbt unzip wget git openssh-server
EXPOSE 80

ARG CACHEBUST=1
RUN echo $CACHEBUST
# Download Maproulette V2
RUN git clone https://github.com/maproulette/maproulette2.git
RUN chmod 777 /maproulette2
WORKDIR /maproulette2

# package Maproulette V2
RUN export API_HOST=maproulette.org;sbt clean compile dist
RUN unzip -d / target/universal/MapRouletteV2.zip
WORKDIR /MapRouletteV2

# Install Yarn and Nodejs
RUN curl -sL https://deb.nodesource.com/setup_9.x | bash -
RUN apt-get install -y nodejs
RUN curl -o- -L https://yarnpkg.com/install.sh | bash

ARG FRONTCACHEBUST=1
RUN echo $FRONTCACHEBUST
# Download Maproulette Frontend
RUN git clone https://github.com/osmlab/maproulette3.git /maproulette-frontend
RUN chmod 755 /maproulette-frontend
ADD .env.production /maproulette-frontend/.env.production

# Build the Maproulette Frontend
WORKDIR /maproulette-frontend
RUN export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH";yarn install
RUN export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH";yarn run build
RUN mkdir /MapRouletteV2/static/
RUN cp -rf /maproulette-frontend/build/* /MapRouletteV2/static/

# Retrieve OSM & Mapillary Certificates
WORKDIR /
RUN openssl s_client -showcerts -connect "www.openstreetmap.org:443" -servername www.openstreetmap.org </dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > osm.pem
RUN openssl s_client -showcerts -connect "a.mapillary.com:443" -servername a.mapillary.com </dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > mapillary.pem
RUN keytool -importcert -noprompt -trustcacerts -alias a.mapillary.com -file mapillary.pem -keystore osmcacerts -storepass openstreetmap
RUN keytool -importcert -noprompt -trustcacerts -alias www.openstreetmap.org -file osm.pem -keystore osmcacerts -storepass openstreetmap

# Bootstrap commands
ADD bootstrap.sh /etc/bootstrap.sh
ADD setupServer.sh /MapRouletteV2/setupServer.sh
ADD docker.conf	/MapRouletteV2/conf/docker.conf
RUN chmod 777 /etc/bootstrap.sh
RUN chmod 777 /MapRouletteV2/setupServer.sh
WORKDIR /MapRouletteV2
# Move the truststore to the correct location
RUN mv /osmcacerts conf/

ENTRYPOINT ["/etc/bootstrap.sh"]
