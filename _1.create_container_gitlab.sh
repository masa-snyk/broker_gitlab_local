#!/bin/bash

set -x

#if [ $# -ne 0 ]
#	then
#		echo 'Needs to supply argument'
#		echo '  $1 = <arg>'
#		exit 1
#fi

#IP_ADDR=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | head -1)
IP_ADDR=$(ifconfig en0 | awk '$1 == "inet" {print $2}')

GITLAB_HOME=${PWD}/volume

mkdir -p ${GITLAB_HOME}

DOCKER_NETWORK=mySnykBrokerNetwork

sudo docker run --detach \
	--hostname gitlab.test \
	--publish 443:443 --publish 80:80 \
	--privileged \
	--network ${DOCKER_NETWORK} \
	--restart always \
	--name gitlab \
	--volume ${GITLAB_HOME}/config:/etc/gitlab \
	--volume ${GITLAB_HOME}/logs:/var/log/gitlab \
	--volume ${GITLAB_HOME}/data:/var/opt/gitlab \
	yrzr/gitlab-ce-arm64v8
