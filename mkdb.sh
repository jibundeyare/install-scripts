#!/bin/bash

# @fixme use `read -s password` instead of passing password as an argument

function usage {
	this=$(basename $0)
	cat <<-EOT
	Usage: $this [APP_NAME] [APP_PASSWORD]

	This script creates a new database and a new database user.

	APP_NAME is the application name. It will be used to name the database and the user.
	APP_PASSWORD is the password that will be used to access the database.

	Note that the following application names are not allowed and will raise an error if used:

	- "mysql"
	- "phpmyadmin"
	- "root"

	Example 1: $this foo 123

	This command will:

	- create a database named "foo"
	- create a database user named "foo"
	- set "123" as the password for that database user
	EOT
}

if [ $# -lt 2 ]; then
	usage
	exit 1
else
	# settings
	app_name="$1"
	app_password="$2"

	case "$app_name" in
		"mysql" | "phpmyadmin" | "root")
			echo "error: application name '$app_name' is not allowed"
			exit 1
			;;
	esac

	cat <<-EOT
	APP_NAME: $app_name
	APP_PASSWORD: $app_password

	EOT

	read -p "Press [y/Y] to confirm: " -n 1 answer
	echo ""

	if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
		echo "canceled"
		exit
	fi
fi

# database
cat <<-EOT |
CREATE DATABASE $app_name DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER '$app_name'@'%';
GRANT ALL PRIVILEGES ON $app_name.* TO '$app_name'@'%';
GRANT USAGE ON $app_name.* TO '$app_name'@'%' IDENTIFIED BY '$app_password';
FLUSH PRIVILEGES;
EOT
sudo mysql -p

