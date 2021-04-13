#!/bin/bash

function usage {
	this=$(basename $0)
	cat <<-EOT
	Usage: $this [LOCAL_DOMAIN]

	This script removes a local domain name from the "/etc/hosts" file.

	LOCAL_DOMAIN is the domain name you will be using in your web browser to access a particular project.

	Example: $this foo.local

	This command will:

	- create a backup of the "/etc/hosts" file with a timestamp
	- remove the "foo.local" local domain from the "/etc/hosts"
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

	read -p "Press [y/Y] to confirm: " answer
	echo ""

	if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
		echo "canceled"
		exit
	fi
fi

# check that the script is not run as root
current_id="$(id -nu)"

if [ "$current_id" == "root" ]; then
	echo "this script should not be run as root"
	exit 1
fi

# check that user is a sudoer
sudo_id=$(sudo id -nu)

if [ "$sudo_id" != "root" ]; then
	echo "you must be a sudoer to use this script"
	exit 1
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

# remove domain name from /etc/hosts file
sudo sed -i "/127.0.0.1 $local_domain/d" /etc/hosts

