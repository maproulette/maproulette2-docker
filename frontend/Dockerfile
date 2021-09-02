#Build the environment
FROM node:12 as builder
EXPOSE 3000

RUN apt-get update && apt-get upgrade -y && apt-get install -y jq git

ARG GIT="osmlab/maproulette3"
RUN echo $GIT
ARG CACHEBUST=2
RUN echo $CACHEBUST
# Download Maproulette Frontend
RUN git clone https://github.com/${GIT}.git /maproulette-frontend

WORKDIR /maproulette-frontend
ARG VERSION="LATEST"
RUN echo $VERSION
RUN if [ "${VERSION}" != "LATEST" ]; then git checkout tags/${VERSION} ; fi
RUN chmod 755 /maproulette-frontend
ADD .env.production /maproulette-frontend/.env.production

# Build the Maproulette Frontend
ENV NODE_OPTIONS="--max-old-space-size=8192"
RUN yarn && yarn run build

# Production environment
FROM nginx:1.20.1-alpine
RUN mkdir -p /var/www/maproulette
COPY --from=builder /maproulette-frontend/build /var/www/maproulette
RUN mkdir -p /etc/nginx/sites-enabled
ADD nginx-config /etc/nginx/sites-enabled/maproulette
ADD nginx.conf /etc/nginx/nginx.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
