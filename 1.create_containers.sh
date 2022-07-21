#!/bin/bash

set -x

### Config ===================

DOCKER_NETWORK=mySnykBrokerNetwork

GITLAB_CONTAINER_NAME=gitlab
GITLAB_HOME=${PWD}/volume
GITLAB_HOST=masa.gitlab.test  # this name needs to be in SANS of cert. cert name must be the same.
GITLAB_TOKEN=y9TnMfa7v65Qcvk8mZum

BROKER_CONTAINER_NAME=broker
BROKER_HOST=$(ifconfig en0 | awk '$1 == "inet" {print $2}')
BROKER_TOKEN=xxxxxxx-xxxxx-xxxx-xxxxx
BROKER_PUBLISH_PORT=8000
BROKER_URL=http://${BROKER_HOST}:${BROKER_PUBLISH_PORT}
ACCEPT_JSON_PATH=${PWD}

### ==========================

### Create container for GitLab

mkdir -p ${GITLAB_HOME}

docker run -d \
	--restart always \
	--name ${GITLAB_CONTAINER_NAME} \
	--hostname ${GITLAB_HOST} \
	--network ${DOCKER_NETWORK} \
	-p 443:443 \
	-p 80:80 \
	-v ${GITLAB_HOME}/config:/etc/gitlab \
	-v ${GITLAB_HOME}/logs:/var/log/gitlab \
	-v ${GITLAB_HOME}/data:/var/opt/gitlab \
	yrzr/gitlab-ce-arm64v8

### Create container for GitLab

docker run -d \
	--restart=always \
	--name ${BROKER_CONTAINER_NAME} \
	--network ${DOCKER_NETWORK} \
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

# -e CA_CERT=/private/volume/config/ssl/masa.gitlab.test.crt \


