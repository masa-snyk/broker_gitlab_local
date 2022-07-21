# Broker demo for gitlab local

Snyk Broker set up for locally running GitLab. 
This demo locally runs 2 containers, GitLab and Snyk Broker.
Snyk broker proxies the connection between local GitLab and Snyk platform.

## 0. Prerequisite

You need local DNS server (or /etc/hosts) and CA for issuing locally trusted certificate for HTTPS.

### Docker network

Create docker network.
```
docker network create mySnykBrokerNetwork
 ```

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

## 1. Set up GitLab locally

Now, fire up GitLab.
For the first time to create GitLab container, it takes ~10 minutes (Download the image, Initializing the DB, etc).
After initial boot up is done, 

For this demo, the hostname of GitLab is `gitlab.test`. You can freely change the name, but make sure you also changes the hostnane in scripts.

***Note***: **For some reason, officail GitLab image (`gitlab/gitlab-ee:latest`) didn't work with my M1 Mac, so I used GitLab image built for M1 specifically (`yrzr/gitlab-ce-arm64v8`).**

Run following or execute `1.create_containers.sh`.

```shell
#!/bin/bash

set -x

### =======================
### Config

DOCKER_NETWORK=mySnykBrokerNetwork

GITLAB_CONTAINER_NAME=gitlab
GITLAB_HOME=${PWD}/volume
GITLAB_HOST=gitlab.test  # this name needs to be in SANS of cert. cert name must be the same.

### Prerequites
SSL_PATH=${GITLAB_HOME}/volume/config/ssl

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
```

***Note***: For the first time you create GitLab container, it will also initialise databases and various sub-systems So takes time... (~10min)

## 2. Obtain initial root password

Once GitLab is up, you can retrieve initial root password.
```
docker exec -it gitlab grep 'Password:' /etc/gitlab/initial_root_password
```

Log in to GitLab, then create an access token. 
Creating non-root user is optional.

## 3. Create access token

Once you login, go to user menu on upper right corner.
Then, preference -> Access Token -> Generate new like below

<image src="./asset/access_token.png">

## 4. Fire up Broker with access token & broker token

You need two kind of tokens. 
1. Broker token (To auth Broker <-> Snyk Platform)
   * [Generate credentials for Snyk Broker](https://docs.snyk.io/features/snyk-broker/set-up-snyk-broker/prepare-snyk-broker-for-deployment#generate-credentials-in-the-target-application-for-snyk-broker)

2. GitLab access token (To auth Broker <-> GitLab)
   * This is the token generated in Step 3.

Edit `GITLAB_TOKEN` and `BROKER_TOKEN` in a script `2.create_broker.sh` and run.

```
#!/bin/bash

set -x

### =======================
### Config

DOCKER_NETWORK=mySnykBrokerNetwork

GITLAB_HOST=gitlab.test  # this name needs to be in SANS of cert. cert name must be the same.
GITLAB_TOKEN=y9TnMfa7v65Qcvk8mZum # Replace this with actual Gitlab token

BROKER_CONTAINER_NAME=broker
BROKER_TOKEN=$(cat broker_token) # Replace this with actual Broker token
BROKER_PUBLISH_PORT=8000

### =======================

BROKER_HOST=$(ifconfig en0 | awk '$1 == "inet" {print $2}')
BROKER_URL=http://${BROKER_HOST}:${BROKER_PUBLISH_PORT}
ACCEPT_JSON_PATH=${PWD}

### ==========================
### Create container for Broker

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

Once broker fires up, you should be able to retrieve local GitLab repositories from Snyk UI.


## Additional topics

### Issue new TLS cert and apply

You can issue new TLS cert by:
```
mkcert \
	-cert-file volume/config/ssl/gitlab.test.crt \
	-key-file volume/config/ssl/gitlab.test.key \
	gitlab.test
```

Run following to restart Nginx to take new TLS certs.
```
docker exec -u root gitlab gitlab-ctl hup nginx registry
```

Then access local gitlab UI from your browser, and you should see the HTTPS connection with new cert.
```
open https://masa.gitlab.test
```

### Apply new GitLab configuration

If you modify GitLab config (suchas enabling container registy), run following to restart GitLab to take new configuration.
```
docker exec -u root gitlab gitlab-ctl reconfigure
```

## References

* Configure HTTPS
	* [https://docs.gitlab.com/omnibus/settings/nginx.html#manually-configuring-https](https://docs.gitlab.com/omnibus/settings/nginx.html#manually-configuring-https)


## ToDos

* [ ] Broker for Container registry and agent
