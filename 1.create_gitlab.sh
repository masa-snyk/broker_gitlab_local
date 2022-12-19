#!/bin/bash

set -x

### ==========================
### Config
### ==========================

DOCKER_NETWORK=mySnykBrokerNetwork

GITLAB_CONTAINER_NAME=gitlab
GITLAB_HOME=${PWD}/volume
GITLAB_HOST=gitlab.test  
# here's little hack. Mack OS uses port 5000 for Air-play (which is the default GitLab registry's port.
GITLAB_REGISTRY_PORT=5555 
GITLAB_ROOT_PASSWORD=Passw0rd

### ==========================
### Preparation
### ==========================

if [[ $(uname -m) == 'arm64' ]]; then
  GITLAB_IMAGE=yrzr/gitlab-ce-arm64v8
else
  GITLAB_IMAGE=gitlab/gitlab-ee:latest
fi

mkdir -p ${GITLAB_HOME}

SSL_PATH=${GITLAB_HOME}/config/ssl

mkdir -p ${SSL_PATH}
chmod 755 ${SSL_PATH}

# Get root CA certificate
cp "$(mkcert -CAROOT)/rootCA.pem" ${SSL_PATH}/rootCA.pem

# Generate certs for GitLab instance
mkcert \
	-cert-file ${SSL_PATH}/${GITLAB_HOST}.crt \
	-key-file ${SSL_PATH}/${GITLAB_HOST}.key \
	${GITLAB_HOST} 

### ===========================
### Create container for GitLab
### ===========================

docker run -d \
	--restart always \
	--name ${GITLAB_CONTAINER_NAME} \
	--hostname ${GITLAB_HOST} \
	--network ${DOCKER_NETWORK} \
	-p 443:443 \
	-p 80:80 \
	-p ${GITLAB_REGISTRY_PORT}:${GITLAB_REGISTRY_PORT} \
	-v ${GITLAB_HOME}/config:/etc/gitlab \
	-v ${GITLAB_HOME}/logs:/var/log/gitlab \
	-v ${GITLAB_HOME}/data:/var/opt/gitlab \
	-e GITLAB_OMNIBUS_CONFIG="external_url 'https://${GITLAB_HOST}'; letsencrypt['enabled'] = false; registry_external_url 'https://${GITLAB_HOST}:${GITLAB_REGISTRY_PORT}'; nginx['redirect_http_to_https'] = true; registry_nginx['redirect_http_to_https'] = true; gitlab_rails['initial_root_password'] = '$GITLAB_ROOT_PASSWORD'" \
	${GITLAB_IMAGE} 

echo GitLab Host: ${GITLAB_HOST}
