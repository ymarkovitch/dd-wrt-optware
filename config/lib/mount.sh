#!/bin/sh

is_mounted(){
	local mountPath=$1; shift
	grep -qs $mountPath /proc/mounts
	return $?
}

mount_path(){
	#get the mount point of a path
	local mountPath=$1; shift
	local dfCount=$(df $mountPath | wc -l)
	if [ $dfCount = 1 ]; then
		#unmounted
		return 0
	elif [ $dfCount = 2 ]; then
		df $mountPath | tail -1 | awk '{ print $6 }'
	elif [ $dfCount = 3 ]; then
		df $mountPath | sed '2q;d'
	else
		return 1
	fi
}

unmount_wait(){
	local retry_num=$1; shift
	local wait_time=$1; shift
	n=1
	local last
	for last; do true; done
	while is_mounted $last; do
		echo "umount $@"
		#use the busybox version in-case opt is to be unmounted
		/bin/umount $@ && return 0
		[ $n -ge $retry_num ] && return 1
		sleep $wait_time
		let n+=1
	done
}
