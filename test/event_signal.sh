#!/opt/bin/bash

. config/event/event.sh

event_signal "WPS_EVENT"
echo "return code: $?"
