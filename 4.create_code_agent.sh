#!/bin/bash

set -x

### =================================
### Config
### =================================

DOCKER_NETWORK=mySnykBrokerNetwork

GITLAB_HOST=gitlab.test
GITLAB_TOKEN=$(cat gitlab_token)
SNYK_TOKEN=$(cat snyk_api_token)

CODE_AGENT_CONTAINER_NAME=code_agent
CODE_AGENT_PORT=3000

### =================================
### Preparation
### =================================

GROUP_ID=$(curl -s --header "Authorization: Bearer ${GITLAB_TOKEN}" -X GET "https://${GITLAB_HOST}/api/v4/groups" | jq -r '.[0].path')

### =================================
### Push sample code 
###  - this will push to default repo
### =================================

pushd goof

git init --initial-branch=main
git remote add origin https://${GITLAB_HOST}/${GROUP_ID}/Monitoring.git
git add .
git commit -m "Initial commit"
git push -u origin main

popd

### =================================
### Run Code Agent
### =================================

docker run -d \
	--restart=always \
	--name ${CODE_AGENT_CONTAINER_NAME} \
	--hostname ${CODE_AGENT_CONTAINER_NAME} \
	--network ${DOCKER_NETWORK} \
	-p ${CODE_AGENT_PORT}:${CODE_AGENT_PORT} \
	-e SNYK_TOKEN=${SNYK_TOKEN} \
	-e PORT=${CODE_AGENT_PORT} \
	-e NODE_TLS_REJECT_UNAUTHORIZED=0 \
	snyk/code-agent
