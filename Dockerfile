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
RUN sbt clean compile dist
RUN unzip -d / target/universal/MapRouletteV2.zip
WORKDIR /MapRouletteV2

ARG CACHEBUST=1
RUN echo $CACHEBUST
# Bootstrap commands
ADD bootstrap.sh /etc/bootstrap.sh
ADD setupServer.sh /MapRouletteV2/setupServer.sh
ADD docker.conf	/MapRouletteV2/conf/docker.conf
RUN chmod 777 /etc/bootstrap.sh
RUN chmod 777 /MapRouletteV2/setupServer.sh

ENTRYPOINT ["/etc/bootstrap.sh"]
