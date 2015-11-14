#!/opt/bin/bash

#able to wait and trigger a single event
#whether the event is triggered should be set & checked by the user, as this is just a variable check and set

. /jffs/etc/config/lib/sleep.sh

function event_wait() {
	#the trap used when unsetting the nvram should be managed by the caller, since trap is overriden and there's no way to get the caller's trap
	#args:
	#	sleep_interval event_store_var
	#returns:
	#	0 if the event is triggered, 1 otherwise
	#wait for the subprocesses to kill this
	local sleep_interval sleep_end event_store_var
	sleep_interval=$1; shift
	event_store_var=$1; shift
	sleepf $sleep_interval &
	nvram set $event_store_var=$!
	wait $!
	sleep_end=$?
	nvram unset $event_store_var
	if (( $sleep_end == 0 )); then
		return 1
	else
		return 0
	fi
}

function event_signal() {
	#signal the event by killing the event process
	#args:
	#	event_store_var
	#returns:
	#	0 if the event is fired, 1 otherwise
	local event_store_var pid
	event_store_var=$1; shift
	pid="$(nvram get $event_store_var)"
	if [[ $pid ]]; then
		kill $pid && return 0
	fi
	return 1
}

function event_wait_cleanup(){
	#call this function on trap
	#args:
	#	event_store_var
	local event_store_var
	event_store_var=$1; shift
	#kill the dangling sleep process
	#	the code calling event_wait won't run since there's a trap condition
	if ! event_signal $event_store_var; then
		#unset in case the dangling process doesn't exist anymore
		nvram unset $event_store_var
	fi
}
