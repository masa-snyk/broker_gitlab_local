#!/bin/bash

set -x

### =================================
### Config
### =================================

DOCKER_NETWORK=mySnykBrokerNetwork

GITLAB_HOST=gitlab.test
GITLAB_USER=root
GITLAB_PASSWORD=Passw0rd
GITLAB_TOKEN=$(cat gitlab_token)
GITLAB_CONTAINER_REPO=monitoring
GITLAB_REGISTRY_PORT=5555
TAG=latest
BROKER_TOKEN=$(cat cr_broker_token)
BROKER_PUBLISH_PORT=8001
BROKER_CONTAINER_NAME=cr_broker

CRA_CONTAINER_NAME=cra
CRA_AGENT_PORT=8081

### =================================
### Preparation
### =================================

GITLAB_REGISTRY_HOST=${GITLAB_HOST}:${GITLAB_REGISTRY_PORT}
GROUP_ID=$(curl -s --header "Authorization: Bearer ${GITLAB_TOKEN}" -X GET "https://${GITLAB_HOST}/api/v4/groups" | jq -r '.[0].path')

BROKER_HOST=$(ifconfig en0 | awk '$1 == "inet" {print $2}')
BROKER_URL=http://${BROKER_HOST}:${BROKER_PUBLISH_PORT}

CR_AGENT_URL=http://$(ifconfig en0 | awk '$1 == "inet" {print $2}'):${CRA_AGENT_PORT}
CR_TYPE=gitlab-cr
CR_BASE=${GITLAB_HOST}:${GITLAB_REGISTRY_PORT}
CR_USERNAME=${GITLAB_USER}
# CR_PASSWORD=${GITLAB_PASSWORD}
CR_PASSWORD=$(cat gitlab_token)

#CA_PATH=${PWD}/volume/config/ssl
#CA_CERT=rootCA.pem

### =================================
### Docker build
###  - this will push to default repo
### =================================

echo ${GITLAB_PASSWORD} | docker login -u ${GITLAB_USER} --password-stdin ${GITLAB_REGISTRY_HOST}
docker build -t ${GITLAB_REGISTRY_HOST}/${GROUP_ID}/${GITLAB_CONTAINER_REPO}:${TAG} . 
docker push ${GITLAB_REGISTRY_HOST}/${GROUP_ID}/${GITLAB_CONTAINER_REPO}:${TAG}

### =================================
### Run Broker client for container registry
### =================================

docker run -d \
	--restart=always \
	--name ${BROKER_CONTAINER_NAME} \
	--hostname ${BROKER_CONTAINER_NAME} \
	--network ${DOCKER_NETWORK} \
	-p ${BROKER_PUBLISH_PORT}:${BROKER_PUBLISH_PORT} \
	-e BROKER_TOKEN=${BROKER_TOKEN} \
	-e BROKER_CLIENT_URL=${BROKER_URL} \
	-e CR_AGENT_URL=${CR_AGENT_URL} \
	-e CR_TYPE=${CR_TYPE} \
	-e CR_BASE=${CR_BASE} \
	-e CR_USERNAME=${CR_USERNAME} \
	-e CR_PASSWORD=${CR_PASSWORD} \
	-e BROKER_CLIENT_VALIDATION_URL=${CR_AGENT_URL}/systemcheck \
	-e PORT=${BROKER_PUBLISH_PORT} \
	-e NODE_TLS_REJECT_UNAUTHORIZED=0 \
	snyk/broker:container-registry-agent 

### =================================
### Run Container Registry Agent
### =================================

docker run -d \
	--restart=always \
	--name ${CRA_CONTAINER_NAME} \
	--hostname ${CRA_CONTAINER_NAME} \
	--network ${DOCKER_NETWORK} \
	-p ${CRA_AGENT_PORT}:${CRA_AGENT_PORT} \
	-e SNYK_PORT=${CRA_AGENT_PORT} \
	-e NODE_TLS_REJECT_UNAUTHORIZED=0 \
	snyk/container-registry-agent:latest

