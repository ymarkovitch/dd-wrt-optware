#!/bin/sh

#asus RT-N16 specific
GPIO_LED=1
GPIO_WPS_BUTTON=8

flash_led() {
	#args:
	#	flash_led count usec_off usec_on
	#	-1 to flash forever
	#flash on first, as the power light is off by default
	local counter=$1; shift
	local off=$1; shift
	local on=$1; shift
	
	while [ $counter -ne 0 ]; do
		#led off
		gpio enable $GPIO_LED
		/bin/usleep $off
		#led on
		gpio disable $GPIO_LED
		/bin/usleep $on
		if [ $counter -ge 0 ]; then
			let counter-=1
		fi
	done
}

led_on() {
	gpio disable $GPIO_LED
}

led_off() {
	gpio enable $GPIO_LED
}
