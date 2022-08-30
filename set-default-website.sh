#!/bin/bash

function usage {
	this=$(basename $0)
	cat <<-EOT
	Usage: $this [VHOST_DIRECTORY]

	This script sets the default website.

	VHOST_DIRECTORY is the directory in which a particular project will be stored.

	Example 1: $this foo

	This command will:

	- make the website foo the default website

	Example 2: $this www

	This command will:

	- reset the website www as the default one

	NOTICE : use the command 'ls /etc/apache2/sites-available' to see the list of all websites.

	EOT
}

if [ $# -lt 1 ]; then
	usage
	exit 1
else
	# settings
	vhost_directory="$1"

	cat <<-EOT
	VHOST_DIRECTORY: $vhost_directory

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
	echo "error: this script should not be run as root"
	exit 1
fi

# check that user is a sudoer
sudo_id=$(sudo id -nu)

if [ "$sudo_id" != "root" ]; then
	echo "error: you must be a sudoer to use this script"
	exit 1
fi

# check that the vhost exists
if [ ! -f "/etc/apache2/sites-available/$vhost_directory.conf" ]; then
	echo "error: the apache2 vhost file '/etc/apache2/sites-available/$vhost_directory.conf' does not exists"
	echo ""
	echo "Did youy forget to create the website with mkwebsite.sh first?"
	exit 1
fi

# remove symbolic link pointing to the old default website vhost
sudo rm /etc/apache2/sites-enabled/000-default.conf

# create symbolic link pointing to the new default website vhost
sudo ln -s ../sites-available/$vhost_directory.conf /etc/apache2/sites-enabled/000-default.conf

# restart apache2
sudo systemctl restart apache2.service

