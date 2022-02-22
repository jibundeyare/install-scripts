#!/bin/bash

function usage {
	this=$(basename $0)
	cat <<-EOT
	Usage: $this [VHOST_DIRECTORY]

	This script disables the specified Apache2 vhost file and delete the associated vhost and PHP-FPM pool files.

	Warning: this script will never delete the project directory or any project file in the project directory.

	VHOST_DIRECTORY is the directory in which a particular project will be stored.

	Example: $this foo

	This command will:

	- delete the Apache2 vhost file "/etc/apache2/sites-available/foo.conf"
	- delete the PHP-FPM pool file "/etc/php/X.Y/fpm/pool.d/foo.conf"
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

# set phpX.Y version
php_version="8.1"

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

# disable vhost
sudo a2dissite $vhost_directory

# remove vhost config from apache2 available vhost directory
sudo rm /etc/apache2/sites-available/$vhost_directory.conf

# restart apache2
sudo systemctl reload apache2.service

# inform user
echo "apache2 reloaded"

# remove pool config from php fpm pool directory
sudo rm /etc/php/$php_version/fpm/pool.d/$vhost_directory.conf

# restart php fpm
sudo systemctl restart php$php_version-fpm.service

# remove the dedicated php session directory
sudo rm -r /var/lib/php/sessions/$vhost_directory

