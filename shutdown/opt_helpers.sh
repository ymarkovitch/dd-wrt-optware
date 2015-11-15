
. /jffs/etc/config/lib/led.sh
. /jffs/etc/config/shutdown/shutdown_helpers.sh

shutdown_success(){
	shutdown_log "successfully shutdown"
	#switch off power led to show the script has finished (it's not switched off by just killing $flash_pid)
	local flash_pid=$1; shift
	kill $flash_pid
	led_off
	exit 0
}

shutdown_fail(){
	shutdown_log "failed to shutdown"
	#keep power led on
	local flash_pid=$1; shift
	kill $flash_pid
	led_on
	exit 1
}
