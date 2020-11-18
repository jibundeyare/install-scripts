#!/bin/bash

function usage {
	this=$(basename $0)
	cat <<-EOT
	Usage: $this [APP_NAME]

	This script creates a new database and a new database user.
	It will ask you to set a password for the user.

	APP_NAME is the application name. It will be used to name the database and the user.

	Note that the following application names are not allowed and will raise an error if used:

	- "mysql"
	- "phpmyadmin"
	- "root"

	Example 1: $this foo

	This command will:

	- ask you to set a password for user "foo"
	- create a database named "foo"
	- create a database user named "foo"
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

	EOT

	read -p "Press [y/Y] to confirm: " -n 1 answer
	echo ""

	if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
		echo "canceled"
		exit
	fi
fi

# set password
echo ""
echo -n "user $app_name's password: "
read -s app_password
echo ""
echo -n "confirm password: "
read -s app_password2
echo ""
echo ""

if [ "$app_password" != "$app_password2" ]; then
	echo "error: user $app_name's passwords did not match"
	exit 1
fi

# database
cat <<-EOT |
CREATE DATABASE $app_name DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER '$app_name'@'%';
GRANT USAGE ON *.* TO '$app_name'@'%' IDENTIFIED BY '$app_password';
GRANT ALL PRIVILEGES ON $app_name.* TO '$app_name'@'%';
FLUSH PRIVILEGES;
EOT
sudo mysql -p

