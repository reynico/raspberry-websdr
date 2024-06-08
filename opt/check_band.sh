#!/bin/bash
set -e

if [ $# -eq 0 ]; then
    echo "Usage: ./check_band.sh BAND. example: ./check_band.sh 40"
fi

BAND="$1"

if pgrep -x "websdr-rpi" > /dev/null
then
	echo "Running"
else
	sudo systemctl start websdr@${BAND}.service
	sudo kill -9 $(pidof rtl_tcp)
	sleep 3
	sudo renice -10 $(pidof rtl_tcp)
	sudo renice -10 $(pidof websdr-rpi)
	if [ "$BAND" == "80" ]; then
		echo 1 > /sys/class/gpio/gpio3/value
	else
		echo 0 > /sys/class/gpio/gpio3/value
	fi
fi
