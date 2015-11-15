#!/opt/bin/bash

SHUTDOWN_EVENT="SHUTDOWN_EVENT"

#feedback parameters, don't export as there can be name collisions
LED_OFF=40000
LED_ON=40000

#maximum wait time for optware shutdown
MAX_WAIT_INTERVAL=-1

#change current dir so jffs can be unmounted
cd /
. /jffs/etc/config/lib/event.sh
. /jffs/etc/config/lib/mount.sh
. /jffs/etc/config/shutdown/opt_helpers.sh

function shutdown_optware_signal(){
	#disable optware auto-unmount
	chmod -x /opt/etc/init.d/K*automount
	/opt/etc/init.d/optK
	event_signal $SHUTDOWN_EVENT || true
}

function shutdown_optware_cleanup(){
	#some services might think that they are not running if they did not startup properly
	pgrep dbus-daemon && (shutdown_log "stopping dbus"; service dbus stop)
	
	if pgrep S99mypage; then
		shutdown_log "stopping mypage"
		#get process pid's
		pid=$(pgrep S99mypage | head -1)
		pgid=$(ps x -o "%p %r" | egrep "\s*$pid\s+[0-9]+" | sed -E 's/^\s*[0-9]+\s*//')
		#stop mypage
		service mypage stop
		#kill mypage's dangling sleep process
		shutdown_log "killing mypage's dangling processes, pgid: $pgid"
		kill -- "-$pgid"
	fi
}

function shutdown_unmount(){
	if ! is_mounted '/opt'; then
		return
	fi
	shutdown_log "some partitions weren't unmounted by automount, running opt_sh.sh to unmount partitions"
	shutdown_optware_cleanup
	#switch shell to /bin/sh as bash has handles using /opt
	#	can't remount /opt as read-only, as partitions can't unmount normally even if mounted read-only
	#	can't copy bash to /tmp as it might have unknown lib dependencies (dlopen/dlsym, equivalent of GetProcAddress)
	#	synchronization locks (flock) are inherited after switching to /bin/sh
	exec /bin/sh "/jffs/etc/config/shutdown/opt_sh.sh" $flash_pid
}

function main(){
	trap "event_wait_cleanup $SHUTDOWN_EVENT; exit 1;" INT TERM
	#run init.d stop script, this handles unmounting of both /mnt and /opt
	shutdown_log "shutting down optware"
	shutdown_optware_signal &
	#wait for the shutdown script to finish, and flash led's while doing so, to show that the script is working
	#	sh is used so that the process can be killed when switching to /bin/sh
	#	the feedback parameters are escaped with '$'
	/bin/sh -c "
		. /jffs/etc/config/lib/led.sh
		flash_led -1 $LED_OFF $LED_ON
	" &
	flash_pid=$!
	trap "event_wait_cleanup $SHUTDOWN_EVENT; shutdown_fail $flash_pid;" INT TERM
	if ! event_wait $MAX_WAIT_INTERVAL $SHUTDOWN_EVENT; then
		#optware shutdown timed out
		shutdown_log "optware shutdown timed out"
		event_wait_cleanup $SHUTDOWN_EVENT
		shutdown_fail $flash_pid
	fi
	trap "shutdown_fail $flash_pid;" INT TERM
	shutdown_log "optware shutdown completed"
	shutdown_log "checking if partitions are still mounted (automount doesn't unmount /opt)"
	#try to unmount partitions if still mounted
	shutdown_unmount
	#control not transferred to sh, hence all partitions are unmounted
	shutdown_log "partitions already unmounted by automount"
	shutdown_success $flash_pid
}

main
