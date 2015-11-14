#!/opt/bin/bash

function sleepf(){
	#sleep forever if -1
	local timeout
	timeout=$1; shift
	if (( timeout == -1)); then
		exec tail -f /dev/null
	else
		exec sleep $timeout
	fi
}
