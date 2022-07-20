#!/bin/bash

set -x

# IP_ADDR=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | head -1)
IP_ADDR=$(ifconfig en0 | awk '$1 == "inet" {print $2}')

CONTAINER_NAME=snyk_gitlab_broker
DOCKER_NETWORK=mySnykBrokerNetwork
BROKER_TOKEN=350a39e2-3e4a-491a-a7ff-eb51ca9e2442
BROKER_PUBLISH_PORT=8000
BROKER_URL=http://${IP_ADDR}:${BROKER_PUBLISH_PORT}
ACCEPT_JSON_PATH=${HOME}/demo/broker/broker_gitlab_local

GITLAB_TOKEN=y9TnMfa7v65Qcvk8mZum
GITLAB_HOST=${IP_ADDR}

docker run -d --restart=always \
	         --name ${CONTAINER_NAME} \
					 --network ${DOCKER_NETWORK} \
           -p ${BROKER_PUBLISH_PORT}:${BROKER_PUBLISH_PORT} \
           -e NODE_TLS_REJECT_UNAUTHORIZED=0 \
           -e BROKER_TOKEN=${BROKER_TOKEN} \
           -e GITLAB_TOKEN=${GITLAB_TOKEN} \
           -e GITLAB=${GITLAB_HOST} \
           -e PORT=${BROKER_PUBLISH_PORT} \
           -e BROKER_CLIENT_URL=${BROKER_URL} \
           -e ACCEPT=/private/accept.json \
					 -e CA_CERT=/private/certs/gitlab.test.cer \
           -v ${ACCEPT_JSON_PATH}:/private \
       snyk/broker:gitlab 
