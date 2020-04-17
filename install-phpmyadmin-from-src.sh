#!/bin/bash

function usage {
	this=$(basename $0)
	cat <<-EOT
	Usage: $this [USERNAME] [DBA_USERNAME] [PMA_SUBDIRECTORY] [PMA_VERSION] 

	This script installs phpMyAdmin **from source** and configures the phpMyAdmin database administrator account.
	It also adds HTTP authentication to phpMyAdmin.
	It will first ask you for an HTTP authentication password and then the phpMyAdmin password.

	If you need to change the HTTP authentication password, you can use the "reset-pma-http-auth-password.sh" script.

	Warning: this script needs pwgen to run.
	Use 'apt install pwgen' to install it.

	USERNAME should be your username.
	DBA_USERNAME should be different from your username.
	PMA_SUBDIRECTORY is the sub directory to access phpMyAdmin with your web browser
	PMA_VERSION is the version of phpMyAdmin you want to install

	Example: $this johndoe dba pma_subdir 5.0.2

	This command will:

	- ask for an HTTP authentication password for phpMyAdmin database administrator "dba"
	- ask for a phpMyAdmin password for phpMyAdmin database administrator "dba"
	- download source from "https://files.phpmyadmin.net/phpMyAdmin/5.0.2/phpMyAdmin-5.0.2-all-languages.tar.gz"
	- install phpMyAdmin 5.0.2
	- make phpMyAdmin accessible with the "http://127.0.0.1/pma_subdir" url
	EOT
}

if [ $# -lt 4 ]; then
	usage
	exit 1
else
	# settings
	username="$1"
	dba_username="$2"
	pma_subdirectory="$3"
	pma_version="$4"

	cat <<-EOT
	USERNAME: $username
	DBA_USERNAME: $dba_username
	PMA_SUBDIRECTORY: $pma_subdirectory
	PMA_VERSION: $pma_version

	EOT

	read -p "Press [y/Y] to confirm: " -n 1 answer
	echo ""

	if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
		echo "canceled"
		exit
	fi
fi

# check if pwgen is installed
if ! [ -x "$(command -v pwgen)" ]; then
	echo "error: pwgen is not installed"
	echo "use 'apt install pwgen' to install it"
	exit 1
fi

# check if phpmyadmin is not already installed
if [ -d /usr/share/phpmyadmin ]; then
	echo "error: phpMyAdmin is already installed in directory '/usr/share/phpmyadmin'"
	exit 1
fi

# download source
if [ ! -f phpMyAdmin-$pma_version-all-languages.tar.gz ]; then
	wget https://files.phpmyadmin.net/phpMyAdmin/$pma_version/phpMyAdmin-$pma_version-all-languages.tar.gz
fi

if [ ! -f phpMyAdmin-$pma_version-all-languages.tar.gz ]; then
	echo "error: unable to download archive from 'https://files.phpmyadmin.net/phpMyAdmin/$pma_version/phpMyAdmin-$pma_version-all-languages.tar.gz'"
	exit 1
fi

# set http authentication password
if [ ! -f /etc/phpmyadmin/htpasswd.login ]; then
	echo ""
	echo "$dba_username's HTTP authentication password"
	htpasswd -c ~/htpasswd.login $dba_username

	if [ "$?" -ne 0 ]; then
		echo ""
		echo "error: could not set $dba_username's HTTP authentication password"
		exit 1
	fi
fi

# set password
echo ""
echo -n "$dba_username's phpmyadmin password: "
read -s password
echo ""
echo -n "confirm password: "
read -s password2
echo ""
echo ""

if [ "$password" != "$password2" ]; then
	echo "error: the $dba_username's phpmyadmin passwords did not match"
	exit 1
fi

# create /etc/phpmyadmin directory
sudo mkdir -p /etc/phpmyadmin

# install http authentication password
if [ ! -f /etc/phpmyadmin/htpasswd.login ]; then
	sudo mv ~/htpasswd.login /etc/phpmyadmin/htpasswd.login
fi

# decompress archive
tar -xf phpMyAdmin-$pma_version-all-languages.tar.gz

# move phpmyadmin directory to its default location
sudo mv phpMyAdmin-$pma_version-all-languages/ /usr/share/phpmyadmin

# create phpmyadmin temporary working directory
sudo mkdir -p /var/lib/phpmyadmin/tmp

# set owner of the phpmyadmin working directory
sudo chown -R $username:$username /var/lib/phpmyadmin

# copy phpmyadmin configuration file
sudo cp phpmyadmin.config.inc.php /usr/share/phpmyadmin/config.inc.php

# set blowfish_secret
# $cfg['blowfish_secret'] = ''; /* YOU MUST FILL IN THIS FOR COOKIE AUTH! */
# =>
# $cfg['blowfish_secret'] = '3gzVBSg3HTbg7cNAX8xVGVkLGZU7t5Fk'; /* YOU MUST FILL IN THIS FOR COOKIE AUTH! */
blowfish_secret="$(pwgen -s 32 1)"
sudo sed -i "s/{blowfish_secret}/$blowfish_secret/" /usr/share/phpmyadmin/config.inc.php

# set controlpass
# // $cfg['Servers'][$i]['controlpass'] = 'pmapass';
# =>
# $cfg['Servers'][$i]['controlpass'] = 'aEysDfbpFRnrMrEvbubWR4eMhT7CyBmj';
pmapass="$(pwgen -s 32 1)"
sudo sed -i "s/{pmapass}/$pmapass/" /usr/share/phpmyadmin/config.inc.php

# copy phpmyadmin apache configuration file
sudo cp phpmyadmin-apache2.conf /etc/apache2/conf-available/phpmyadmin.conf

# set sub directory
# Alias /phpmyadmin /usr/share/phpmyadmin
# =>
# Alias /custom_pma /usr/share/phpmyadmin
sudo sed -i "s/{pma_subdirectory}/$pma_subdirectory/g" /etc/apache2/conf-available/phpmyadmin.conf

# enable phpmyadmin conf
sudo a2enconf phpmyadmin.conf

# restart apache2
sudo systemctl restart apache2.service

# create phpmyadmin tables
sudo mariadb < /usr/share/phpmyadmin/sql/create_tables.sql

# grant required privileges to pma account and set password
echo "GRANT SELECT, INSERT, UPDATE, DELETE ON phpmyadmin.* TO 'pma'@'localhost' IDENTIFIED BY '$pmapass';" | sudo mysql

# grant required privileges to phpmyadmin database administrator account and set password
echo "GRANT ALL PRIVILEGES ON *.* TO '$dba_username'@'localhost' IDENTIFIED BY '$password' WITH GRANT OPTION;" | sudo mysql
echo "FLUSH PRIVILEGES;" | sudo mysql

