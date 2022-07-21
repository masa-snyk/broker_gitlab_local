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
