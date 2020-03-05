#!/bin/bash

function usage {
	this=$(basename $0)
	cat <<-EOT
	Usage: $this [HTTP_AUTH_USERNAME]

	This script resets the HTTP authentication password that was set for PHPMyAdmin.
	It will ask you for an HTTP authentication password.
	Previous user name and password combination will be overwritten.

	HTTP_AUTH_USERNAME can be any user name, your linux user name or another one.

	Example: $this johndoe

	This command will:

	- ask for a password for "johndoe"
	- create an HTTP authentication with user name "johndoe" and the specified password
	- and do some other things (see the source)
	EOT
}

if [ $# -lt 1 ]; then
	usage
	exit 1
else
	# settings
	http_auth_username="$1"

	cat <<-EOT
	HTTP_AUTH_USERNAME: $http_auth_username

	This will reset existing HTTP authentication user name and password.

	EOT

	read -p "Press [y/Y] to confirm: " -n 1 answer
	echo ""

	if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
		echo "canceled"
		exit
	fi
fi

# create http authentication password
echo "HTTP authentication password for login '$http_auth_username'"
sudo htpasswd -c /etc/phpmyadmin/htpasswd.login $http_auth_username

