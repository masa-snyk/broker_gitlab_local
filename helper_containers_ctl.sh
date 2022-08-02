#!/bin/bash

set -x

if [ $# -ne 2 ]
	then
		echo 'Needs to supply argument'
		echo '  $1 = <stop|start>'
		echo '  $2 = <gitlab|broker|cr_broker>'
		exit 1
fi

docker ${1} ${2}
 
