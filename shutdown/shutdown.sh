#!/bin/sh

#jffs remount wrapper to the main shutdown script, so the main shutdown script can run without interruption

#note that during testing the console might correctly show that the script has exited, even when it has

#to test:
#	start in /opt as /jffs is unmounted first
#	$ cd /
#	$ exec /bin/sh
#	$ /opt/jffs/etc/config/shutdown/shutdown.sh

#to test for error handling when opt unmounting fails:
#	$ cd /opt
#	$ /opt/jffs/etc/config/shutdown/shutdown.sh

export PATH=/opt/bin:/opt/sbin:/opt/usr/sbin:$PATH

#ensure the shutdown script is only run once
LOCK_PATH="/tmp/SHUTDOWN.LCK"
LOCK_FILE=3
eval "exec $LOCK_FILE> $LOCK_PATH"
SHUTDOWN_STAGE="SHUTDOWN_STAGE"
SHUTDOWN_RES="SHUTDOWN_RES"

#mount /tmp to /jffs on startup:
#	the final unmount script & background processes during it's execution should have no handles to mounted partitions,
#	but as there are library dependencies at all stages, and the import paths cannot change, we need to copy imported scripts to /tmp, and remount a partition
#	relative paths (calculating the path to use by checking what is mounted) makes this easier, as a script can be run before or after remounting without modification
#	process:
#		use import scripts on partition #1
#		unmount partition #2, and remount it in /tmp
#		close unmount script (seperate script so we can close it's imports too)
#		use import scripts on /tmp
#		unmount partition #1
#	if we remount /jffs:
#		we remount on startup instead of just before switching shells, since automount unmounts /jffs if it's not on ramfs
#		(automount only unmounts hdd partitions, not ramfs, so it won't unmount what we have just mounted)
#	if we remount /opt:
#		we have to remount after running optK, as service scripts require /opt when running 'service ... stop'

remount_jffs_tmp_wait(){
	if ! unmount_wait 2 1 /jffs; then
		shutdown_log_unmount_fail /jffs
		return 1
	fi
	#copy the scripts required for shutdown to /tmp, so no handles to /opt or /jffs are kept
	tmp_jffs_init_shutdown
}

remount_jffs_tmp(){
	. /opt/jffs/etc/config/lib/mount.sh
	. /opt/jffs/etc/config/shutdown/jffs_helpers.sh
	. /opt/jffs/etc/config/shutdown/shutdown_helpers.sh
	shutdown_log "remounting jffs to tmp"
	remount_jffs_tmp_wait
	local res=$?
	if [ $res = 0 ]; then
		/jffs/etc/config/shutdown/shutdown.sh &
	else
		shutdown_log "failed to remount jffs"
		return $res
	fi
}

unmount_opt(){
	. /jffs/etc/config/lib/led.sh
	. /jffs/etc/config/shutdown/jffs_helpers.sh
	. /jffs/etc/config/shutdown/shutdown_helpers.sh
	/jffs/etc/config/shutdown/opt.sh
	local res=$?
	#clean jffs tmp to save ram
	tmp_jffs_close
	if [ $res = 0 ]; then
		#commit nvram on successful shutdown
		nvram commit
		#nvram commit turns the power led back on
		led_off
		return $res
	else
		#switch paths so we can remount jffs
		#store exit code of unmount reason for failure
		nvram set $SHUTDOWN_RES=$res
		/opt/jffs/etc/config/shutdown/shutdown.sh &
	fi
}

remount_jffs_opt(){
	. /opt/jffs/etc/config/shutdown/jffs_helpers.sh
	. /opt/jffs/etc/config/shutdown/shutdown_helpers.sh
	local res=$(nvram get $SHUTDOWN_RES)
	nvram unset $SHUTDOWN_RES
	#remount jffs so shutdown can be performed again using the wps button
	shutdown_log "remounting jffs to opt"
	jffs_mount_opt
	#always return to the first stage, as we remount jffs to tmp again
	nvram unset $SHUTDOWN_STAGE
	return $res
}

shutdown_main(){
	#no traps needed
	cd /
	#don't use nvram or tmp to store the stage of shutdown, to be safer in cases with unusual mount points, and so some stages can run independently
	#	(e.g. when /jffs is unmounted but /opt is, or when debugging the shutdown script)
	local scriptDir=$(dirname $(readlink -f $0))
	. "${scriptDir}/../lib/mount.sh" || return
	if is_mounted /jffs && is_mounted /opt; then
		if [ $(mount_path /jffs) = "/tmp" ] || [ $(mount_path /jffs) = "/jffs" ]; then
			if ! [ $(nvram get $SHUTDOWN_RES) ]; then
				unmount_opt
				return $?
			else
				#unmounting opt has failed, remount jffs
				remount_jffs_opt
				return $?
			fi
		else
			#remount jffs to opt to prepare for unmounting opt
			remount_jffs_tmp
			return $?
		fi
	elif is_mounted /jffs; then
		shutdown_log "error: jffs is mounted but opt is not"
		return 1
	elif is_mounted /opt; then
		remount_jffs_opt
		return $?
	else
		return
	fi
}

main(){
	#if multiple processes use the critical section, SHUTDOWN_STAGE ensures that they run in sequence
	rm $LOCK_PATH
	flock -x $LOCK_FILE
	shutdown_main
	local res=$?
	exit $res
}

main
