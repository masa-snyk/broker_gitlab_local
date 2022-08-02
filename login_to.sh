#!/bin/bash

set -x

if [ $# -ne 1 ]
	then
		echo 'Needs to supply argument'
		echo '  $1 = <broker|gitlab|ca_broker|cra>'
		exit 1
fi

docker exec -u root -it ${1} /bin/sh 
