#!/bin/bash

set -x

#if [ $# -ne 0 ]
#	then
#		echo 'Needs to supply argument'
#		echo '  $1 = <arg>'
#		exit 1
#fi

GITLAB_HOME=${HOME}/demo/broker/broker_gitlab_local/volume

sudo docker run --detach \
	--hostname gitlab.local \
	--publish 443:443 --publish 80:80 \
	--privileged \
	--restart always \
	--name gitlab \
	--volume ${GITLAB_HOME}/config:/etc/gitlab \
	--volume ${GITLAB_HOME}/logs:/var/log/gitlab \
	--volume ${GITLAB_HOME}/data:/var/opt/gitlab \
	yrzr/gitlab-ce-arm64v8
