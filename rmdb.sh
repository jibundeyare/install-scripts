#!/bin/bash

function usage {
	this=$(basename $0)
	cat <<-EOT
	Usage: $this [APP_NAME]

	This script drops the specified database and database user.

	APP_NAME is the application name. It will be used for the database name and the database user.

	Note that the following application names are not allowed and will raise an error if used:

	- "mysql"
	- "phpmyadmin"
	- "root"

	Example 1: $this foo

	This command will:

	- drop the database named "foo"
	- drop the database user named "foo"
	EOT
}

if [ $# -lt 1 ]; then
	usage
	exit 1
else
	# settings
	app_name="$1"

	case "$app_name" in
		"mysql" | "phpmyadmin" | "root")
			echo "error: application name '$app_name' is not allowed"
			exit 1
			;;
	esac

	cat <<-EOT
	APP_NAME: $app_name

	Warning: please backup your database before dropping it!

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

echo "enter mariadb root password (which can be blank)"

# database
cat <<-EOT |
DROP USER '$app_name'@'localhost';
DROP DATABASE $app_name;
FLUSH PRIVILEGES;
EOT
sudo mysql -p

