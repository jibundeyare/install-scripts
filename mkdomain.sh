#!/bin/bash

function usage {
	this=$(basename $0)
	cat <<-EOT
	Usage: $this [LOCAL_DOMAIN]

	This script adds a local domain name to the "/etc/hosts" file.

	LOCAL_DOMAIN is the domain name you will be using in your web browser to access a particular project.

	Example: $this foo.local

	This command will:

	- create a backup of the "/etc/hosts" file with a timestamp
	- add the "foo.local" local domain to the "/etc/hosts"
	EOT
}

if [ $# -lt 1 ]; then
	usage
	exit 1
else
	# settings
	local_domain="$1"

	cat <<-EOT
	LOCAL_DOMAIN: $local_domain

	EOT

	read -p "Press [y/Y] to confirm: " -n 1 answer
	echo ""

	if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
		echo "canceled"
		exit
	fi
fi

# backup /etc/hosts file
if [ ! -f /etc/hosts.orig ]; then
	# backup original hosts file
	sudo cp /etc/hosts /etc/hosts.orig
else
	# get timestamp
	timestamp=$(date "+%Y%m%d%H%M%S")

	# backup /etc/hosts file with a timestamp
	sudo cp /etc/hosts /etc/hosts-$timestamp
fi

# add domain name to /etc/hosts file
sudo sed -i "s/\\(127\\.0\\.0\\.1\\s\\+.*\\)/\\1 $local_domain/" /etc/hosts

