#!/bin/sh

#this file should have no imports, as it is loaded both before and after remounts

SHUTDOWN_LOG_PATH=/var/log/shutdown

shutdown_log_raw(){
	echo "$@"
	echo "$@" >> $SHUTDOWN_LOG_PATH
}

shutdown_log(){
	#don't use logger, otherwise only parts of the shutdown log will be present in /opt, which will be confusing
	echo "$@"
	echo $(/bin/date +"%Y %b %e %X") $(/bin/hostname) "optware unmount shutdown ($$): " "$@" >> $SHUTDOWN_LOG_PATH
}

shutdown_log_unmount_fail(){
	local dir=$1; shift
	shutdown_log "failed to unmount $dir"
	shutdown_log "$ lsof $dir"
	shutdown_log_raw "$(lsof $dir)"
}
