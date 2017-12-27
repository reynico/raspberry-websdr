#!/bin/bash
if pgrep -x "websdr-rpi" > /dev/null
then
	echo "Running"
else
	sudo systemctl start websdr@$1.service
	sudo kill -9 `pidof rtl_tcp`
	sleep 3
	sudo renice -10 `pidof rtl_tcp`
	sudo renice -10 `pidof websdr-rpi`
	if [ "$1" == "80" ]; then
		echo 1 > /sys/class/gpio/gpio3/value
	else
		echo 0 > /sys/class/gpio/gpio3/value
	fi
fi
