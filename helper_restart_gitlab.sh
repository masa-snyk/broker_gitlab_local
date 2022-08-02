#!/bin/bash

set -x

docker exec -u root gitlab gitlab-ctl reconfigure 
docker exec -u root gitlab gitlab-ctl hup nginx registry
