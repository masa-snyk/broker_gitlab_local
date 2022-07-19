#!/bin/bash

set -x

#if [ $# -ne 0 ]
#	then
#		echo 'Needs to supply argument'
#		echo '  $1 = <arg>'
#		exit 1
#fi

CONTAINER_NAME=snyk_gitlab_broker
BROKER_TOKEN=fb82802f-2292-4ca2-85c0-c6a987a1df9c
GITLAB_TOKEN=hjn7YUzq_9y9xs17TiXs
GITLAB_HOST=127.0.0.1
BROKER_PUBLISH_PORT=18000
BROKER_URL=http://127.0.0.1:${BROKER_PUBLISH_PORT}
ACCEPT_JSON_PATH=${HOME}/demo/broker/broker_gitlab_local

docker run -d --restart=always \
	         --name ${CONTAINER_NAME} \
           -p ${BROKER_PUBLISH_PORT}:${BROKER_PUBLISH_PORT} \
           -e BROKER_TOKEN=${BROKER_TOKEN} \
           -e GITLAB_TOKEN=${GITLAB_TOKEN} \
           -e GITLAB=${GITLAB_HOST} \
           -e PORT=${BROKER_PUBLISH_PORT} \
           -e BROKER_CLIENT_URL=${BROKER_URL} \
           -e ACCEPT=/private/accept.json \
           -v ${ACCEPT_JSON_PATH}:/private \
       snyk/broker:gitlab 
