#!/bin/bash

set -x

### =======================
### Config

DOCKER_NETWORK=mySnykBrokerNetwork

GITLAB_HOST=masa.gitlab.test  # this name needs to be in SANS of cert. cert name must be the same.
GITLAB_TOKEN=y9TnMfa7v65Qcvk8mZum # Replace this with actual Gitlab token

BROKER_CONTAINER_NAME=broker
BROKER_TOKEN=$(cat broker_token) # Replace this with actual Broker token
BROKER_PUBLISH_PORT=8000

### =======================

BROKER_HOST=$(ifconfig en0 | awk '$1 == "inet" {print $2}')
BROKER_URL=http://${BROKER_HOST}:${BROKER_PUBLISH_PORT}
ACCEPT_JSON_PATH=${PWD}

### ==========================
### Create container for Broker

#	--network ${DOCKER_NETWORK} \

docker run -d \
	--restart=always \
	--name ${BROKER_CONTAINER_NAME} \
	-p ${BROKER_PUBLISH_PORT}:${BROKER_PUBLISH_PORT} \
	-v ${ACCEPT_JSON_PATH}:/private \
	-e BROKER_TOKEN=${BROKER_TOKEN} \
	-e GITLAB_TOKEN=${GITLAB_TOKEN} \
	-e GITLAB=${GITLAB_HOST} \
	-e PORT=${BROKER_PUBLISH_PORT} \
	-e BROKER_CLIENT_URL=${BROKER_URL} \
	-e ACCEPT=/private/accept.json \
	-e NODE_TLS_REJECT_UNAUTHORIZED=0 \
	snyk/broker:gitlab 