#!/bin/bash

set -x

#if [ $# -ne 0 ]
#	then
#		echo 'Needs to supply argument'
#		echo '  $1 = <arg>'
#		exit 1
#fi

docker exec -u root gitlab gitlab-ctl hup nginx registry 
