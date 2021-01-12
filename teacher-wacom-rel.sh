#!/bin/bash

conf_file="teacher-wacom-conf.sh"

if [ ! -f "$conf_file" ]; then
	echo "error: missing conf file '$conf_file'"
	echo ""
	echo "did you forget to create one ?"
	echo "use '$conf_file.dist' as a base file"
	exit 1
fi

source $conf_file

for wacom_device in $wacom_devices; do
	# set wacom tablet to relative mode
	xsetwacom --set $wacom_device Mode Relative
done

