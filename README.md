# Broker demo for gitlab local

Snyk Broker set up for locally running GitLab. 
This demo locally runs 2 containers, GitLab and Snyk Broker.
Snyk broker proxies the connection between local GitLab and Snyk platform.

## Pre-requisite

You need local DNS server (or /etc/hosts) and CA for issuing locally trusted certificate for HTTPS.

### Local DNS server

Host name resolution could be done by ediding /etc/hosts, but it always nice to have your own local DNS server ;-)
Below is example to resolve `*.test` as a local loopback address.

```shell
brew install dnsmasq

# set *.test domain as a local loopback address
echo 'address=/.test/127.0.0.1' >> $(brew --prefix)/etc/dnsmasq.conf

# Make dnsmasq as local DNS for *.test domain
sudo mkdir -v /etc/resolver
sudo bash -c 'echo "nameserver 127.0.0.1" >> /etc/resolver/test'

# Start dnsmasq
sudo brew services start dnsmasq
```

To test if DNS is working, try:
```
ping snyk.test
ping gitlab.test
```

It should route to localhost.


### Local CA

You need locally trusted TLS cert for GitLab server.

```shell
brew install mkcert
mkcert -install # Set up local CA and generate CA cert 
mkcert <hostname> # Generated signed cert for hostname, IP, wildcard, etc
```

If you want to issue a cert for multiple SANS, try:
```
mkcert gitlab.test localhost 127.0.0.1
```

## Create 2 containers

(Contents of `1.create_containers.sh`)

```shell
#!/bin/bash

set -x

### =======================
### Config

DOCKER_NETWORK=mySnykBrokerNetwork

GITLAB_CONTAINER_NAME=gitlab
GITLAB_HOME=${PWD}/volume
GITLAB_HOST=masa.gitlab.test  # this name needs to be in SANS of cert. cert name must be the same.
GITLAB_TOKEN=y9TnMfa7v65Qcvk8mZum

BROKER_CONTAINER_NAME=broker
BROKER_TOKEN=$(cat broker_token)
BROKER_PUBLISH_PORT=8000

### =======================

BROKER_HOST=$(ifconfig en0 | awk '$1 == "inet" {print $2}')
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
```

***Note***: For the first time you create GitLab container, it will also initialise databases and various sub-systems So takes time... (~10min)

## Configure HTTPS

Reference: [https://docs.gitlab.com/omnibus/settings/nginx.html#manually-configuring-https](https://docs.gitlab.com/omnibus/settings/nginx.html#manually-configuring-https)


### Edit config file

Uncomment the line with `exeternal_url` in `volume/config/gitlab.rb`.
Or you can log in to your container and edit `/etc/gitlab/ssl`.
```
external_url "https://masa.gitlab.test"
```
And, disable Let's encrypt section in `gitlab.rb`.
```
letsencrypt['enable'] = false
```

### Issue TLS cert and private key

Run following:

(contents of `3.issue_certs.sh`)

```
#!/bin/bash

set -x

SSL_PATH=${PWD}/volume/config/ssl
HOST_NAME=masa.gitlab.test

mkdir -p ${SSL_PATH}
chmod 755 ${SSL_PATH}

mkcert \
	-cert-file ${SSL_PATH}/${HOST_NAME}.crt \
	-key-file ${SSL_PATH}/${HOST_NAME}.key \
	${HOST_NAME}
```

### Restart GitLab & Nginx

Run following to restart GitLab to take new configuration.
```
docker exec -u root gitlab gitlab-ctl reconfigure
```

Run following to restart Nginx to take new TLS certs.
```
docker exec -u root gitlab gitlab-ctl hup nginx registry
```

Then access local gitlab UI from your browser, and you should see the HTTPS connection is now safe.
```
open https://masa.gitlab.test
```


## ToDos

* [ ] Broker for Container registry and agent