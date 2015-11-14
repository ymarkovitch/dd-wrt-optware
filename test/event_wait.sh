#!/opt/bin/bash

. config/event/event.sh

trap 'event_wait_cleanup "WPS_EVENT"; trap - INT TERM EXIT; exit 2' INT TERM EXIT
event_wait 10 "WPS_EVENT"
echo "return code: $?"
