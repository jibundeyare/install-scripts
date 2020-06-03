#!/bin/bash

function usage {
	this=$(basename $0)
	cat <<-EOT
	Usage: $this [DBA_USERNAME]

	This script resets the HTTP authentication password that was set for PHPMyAdmin.
	It will ask you for an HTTP authentication password.
	Previous user name and password combination will be overwritten.

	DBA_USERNAME can be any user name, your linux user name or another one.

	Example: $this dba

	This command will:

	- ask for an HTTP authentication password for phpMyAdmin database administrator "dba"
	EOT
}

if [ $# -lt 1 ]; then
	usage
	exit 1
else
	# settings
	dba_username="$1"

	cat <<-EOT
	DBA_USERNAME: $dba_username

	This will reset existing HTTP authentication password for phpMyAdmin database administrator "$dba_username".

	EOT

	read -p "Press [y/Y] to confirm: " -n 1 answer
	echo ""

	if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
		echo "canceled"
		exit
	fi
fi

if [ ! -f /etc/phpmyadmin/htpasswd.login ]; then
	echo "error: the file '/etc/phpmyadmin/htpasswd.login' does not exist."
	echo "use './install-phpmyadmin-from-src.sh' to install it"
	exit 1
fi

# create http authentication password
echo "$dba_username's HTTP authentication password"
sudo htpasswd -c /etc/phpmyadmin/htpasswd.login $dba_username

if [ "$?" -ne 0 ]; then
	echo ""
	echo "error: could not set $dba_username's HTTP authentication password"
	exit 1
fi

