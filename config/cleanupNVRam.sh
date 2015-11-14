#!/bin/bash
rm /opt/tmp/nvramshow
nvram show >> /opt/tmp/nvramshow
i=0
while read -r line; do
	val=${line#*=}
	var=${line%*=}
	if [[ "$val" == "" ]]; then
			nvram unset $var
	fi
	i=`expr $i + 1`
	if [[ $i == 50 ]]; then
			sleep 2
			i=0
	fi
done < /opt/tmp/nvramshow
exit 0
