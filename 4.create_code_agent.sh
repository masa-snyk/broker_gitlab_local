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
