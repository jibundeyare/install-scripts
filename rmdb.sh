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

	read -p "Press [y/Y] to confirm: " -n 1 answer
	echo ""

	if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
		echo "canceled"
		exit
	fi
fi

echo "enter sudo password if asked"
echo "then enter mariadb root password (which can be blank)"

# database
cat <<-EOT |
DROP USER '$app_name'@'localhost';
DROP DATABASE $app_name;
FLUSH PRIVILEGES;
EOT
sudo mysql -p

