#!/bin/bash

teacher_wacom_conf_file="teacher-wacom-conf.sh"

if [ ! -f "$teacher_wacom_conf_file" ]; then
	echo "error: missing teacher wacom conf file '$teacher_wacom_conf_file'"
	echo ""
	echo "did you forget to create one ?"
	echo "use '$teacher_wacom_conf_file.dist' as a base file"
	exit 1
fi

source $teacher_wacom_conf_file

for wacom_device in $wacom_devices; do
	# set wacom tablet to relative mode
	xsetwacom --set $wacom_device Mode Relative
done

