#!/bin/bash

set -x

### =======================
### Config
### =======================

DOCKER_NETWORK=mySnykBrokerNetwork

GITLAB_HOST=gitlab.test  # this name needs to be in SANS of cert. cert name must be the same.
GITLAB_TOKEN=$(cat gitlab_token) # Replace this with actual Gitlab token

BROKER_TOKEN=$(cat broker_token) # Replace this with actual Broker token
BROKER_CONTAINER_NAME=broker
BROKER_PUBLISH_PORT=8000

### =======================
### Preparation
### =======================

BROKER_HOST=$(ifconfig en0 | awk '$1 == "inet" {print $2}')
BROKER_URL=http://${BROKER_HOST}:${BROKER_PUBLISH_PORT}
ACCEPT_JSON_PATH=${PWD}

CODE_AGENT_CONTAINER_NAME=code_agent
CODE_AGENT_PORT=3000

### =================================
### Push sample code
###  - this will push to default repo
###  - make sure your Gitlab instance is up&running
### =================================

GROUP_ID=$(curl -s --header "Authorization: Bearer ${GITLAB_TOKEN}" -X GET "https://${GITLAB_HOST}/api/v4/groups" | jq -r '.[0].path')

pushd goof

git init --initial-branch=main
git remote add origin https://${GITLAB_HOST}/${GROUP_ID}/Monitoring.git
git add .
git commit -m "Initial commit"
git push -u origin main

popd

### ==========================
### (New version)
### Create container for Broker with snykCodeBrokerCloning.
### New feature that you don't need CodeAgent anymore.
### Make sure you set `snykCodeBrokerCloning` and `snykCodeAccess` in Snyk Admin page.
### =======================

docker run -d \
	--restart=always \
	--name ${BROKER_CONTAINER_NAME} \
	--hostname ${BROKER_CONTAINER_NAME} \
	--network ${DOCKER_NETWORK} \
	-p ${BROKER_PUBLISH_PORT}:${BROKER_PUBLISH_PORT} \
	-v ${ACCEPT_JSON_PATH}:/private \
	-e BROKER_TOKEN=${BROKER_TOKEN} \
	-e GITLAB_TOKEN=${GITLAB_TOKEN} \
	-e GITLAB=${GITLAB_HOST} \
	-e PORT=${BROKER_PUBLISH_PORT} \
	-e BROKER_CLIENT_URL=${BROKER_URL} \
	-e GIT_CLIENT_URL=http://${CODE_AGENT_CONTAINER_NAME}:${CODE_AGENT_PORT} \
	-e ACCEPT_CODE=true \
	-e NODE_TLS_REJECT_UNAUTHORIZED=0 \
	snyk/broker:gitlab 

# -e ACCEPT=/private/accept.json \
#  -e ACCEPT_IAC=tf.yaml,yml,json,tpl \
#
### ==========================
### (Original version)
### Create container for Broker
### =======================

#docker run -d \
#	--restart=always \
#	--name ${BROKER_CONTAINER_NAME} \
#	--hostname ${BROKER_CONTAINER_NAME} \
#	--network ${DOCKER_NETWORK} \
#	-p ${BROKER_PUBLISH_PORT}:${BROKER_PUBLISH_PORT} \
#	-v ${ACCEPT_JSON_PATH}:/private \
#	-e BROKER_TOKEN=${BROKER_TOKEN} \
#	-e GITLAB_TOKEN=${GITLAB_TOKEN} \
#	-e GITLAB=${GITLAB_HOST} \
#	-e PORT=${BROKER_PUBLISH_PORT} \
#	-e BROKER_CLIENT_URL=${BROKER_URL} \
#	-e GIT_CLIENT_URL=http://${CODE_AGENT_CONTAINER_NAME}:${CODE_AGENT_PORT} \
#	-e ACCEPT=/private/accept.json \
#	-e NODE_TLS_REJECT_UNAUTHORIZED=0 \
#	snyk/broker:gitlab 
#
### =========================
### For Broker HA (Optional)
### ========================

# BROKER_CONTAINER_NAME2=${BROKER_CONTAINER_NAME}2
# BROKER_PUBLISH_PORT2=18000
# BROKER_URL2=http://${BROKER_HOST}:${BROKER_PUBLISH_PORT2}
# 
# docker run -d \
# 	--restart=always \
# 	--name ${BROKER_CONTAINER_NAME2} \
# 	--hostname ${BROKER_CONTAINER_NAME2} \
# 	--network ${DOCKER_NETWORK} \
# 	-p ${BROKER_PUBLISH_PORT2}:${BROKER_PUBLISH_PORT} \
# 	-v ${ACCEPT_JSON_PATH}:/private \
# 	-e BROKER_TOKEN=${BROKER_TOKEN} \
# 	-e GITLAB_TOKEN=${GITLAB_TOKEN} \
# 	-e GITLAB=${GITLAB_HOST} \
# 	-e PORT=${BROKER_PUBLISH_PORT2} \
# 	-e BROKER_CLIENT_URL=${BROKER_URL} \
# 	-e GIT_CLIENT_URL=http://${CODE_AGENT_CONTAINER_NAME}:${CODE_AGENT_PORT} \
# 	-e ACCEPT=/private/accept.json \
# 	-e NODE_TLS_REJECT_UNAUTHORIZED=0 \
# 	snyk/broker:gitlab 
