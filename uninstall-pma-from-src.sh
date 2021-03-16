#!/bin/bash

function usage {
	this=$(basename $0)
	cat <<-EOT
	Usage: $this [DBA_USERNAME]

	This script uninstalls phpMyAdmin.
	But it will proceed only if phpMyAdmin was installed **from source**.

	DBA_USERNAME should be the phpMyAdmin database administrator account you use to log in to phpMyAdmin.

	Example: $this dba

	This command will:

	- uninstall phpMyAdmin
	- remove the phpMyAdmin database administrator "dba"
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

	EOT

	read -p "Press [y/Y] to confirm: " -n 1 answer
	echo ""

	if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
		echo "canceled"
		exit
	fi
fi

# check if phpmyadmin was installed from source
# hide stdout and stderr
sudo dpkg -l phpmyadmin | grep phpmyadmin > /dev/null 2> /dev/null

if [ "$?" -eq 0 ]; then
	echo "error: phpMyAdmin was installed with apt, not from source"
	exit 1
fi

# disable phpmyadmin conf
sudo a2disconf phpmyadmin.conf

# restart apache2
sudo systemctl reload apache2.service

# inform user
echo "apache2 reloaded"

# remove phpmyadmin apache configuration file
sudo rm /etc/apache2/conf-available/phpmyadmin.conf

# remove database
echo "DROP DATABASE IF EXISTS phpmyadmin;" | sudo mysql

# remove phpmyadmin database administrator account
echo "DROP USER IF EXISTS '$dba_username'@'localhost';" | sudo mysql
echo "DROP USER IF EXISTS 'pma'@'localhost';" | sudo mysql
echo "FLUSH PRIVILEGES;" | sudo mysql

# remove phpmyadmin temporary working directory
sudo rm -fr /var/lib/phpmyadmin/tmp

# remove phpmyadmin directory
sudo rm -fr /usr/share/phpmyadmin

# remove /etc/phpmyadmin directory
sudo rm -fr /etc/phpmyadmin

# remove php fpm pool
sudo rm /etc/php/7.4/fpm/pool.d/phpmyadmin.conf

# remove phpmyadmin dedicated php session directory
sudo rm -r /var/lib/php/sessions/phpmyadmin

