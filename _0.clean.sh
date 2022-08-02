#!/bin/bash

set -x

docker rm -f gitlab
docker rm -f broker
docker rm -f cra
docker rm -f cr_broker
docker rm -f code_agent
 
