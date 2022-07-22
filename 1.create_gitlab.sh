#!/bin/bash

set -x

### =======================
### Config

DOCKER_NETWORK=mySnykBrokerNetwork

GITLAB_CONTAINER_NAME=gitlab
GITLAB_HOME=${PWD}/volume
GITLAB_HOST=gitlab.test  # this name needs to be in SANS of cert. cert name must be the same.

### Prerequites

SSL_PATH=${GITLAB_HOME}/config/ssl

mkdir -p ${SSL_PATH}
chmod 755 ${SSL_PATH}

mkcert \
	-cert-file ${SSL_PATH}/${GITLAB_HOST}.crt \
	-key-file ${SSL_PATH}/${GITLAB_HOST}.key \
	${GITLAB_HOST}

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
    -e GITLAB_OMNIBUS_CONFIG="external_url 'https://${GITLAB_HOST}'; letsencrypt['enabled'] = false;" \
	yrzr/gitlab-ce-arm64v8
