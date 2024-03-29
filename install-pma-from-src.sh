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

	Example: $this johndoe dba pma-subdir 5.1.3

	This command will:

	- ask for an HTTP authentication password for phpMyAdmin database administrator "dba"
	- ask for a phpMyAdmin password for phpMyAdmin database administrator "dba"
	- download source from "https://files.phpmyadmin.net/phpMyAdmin/5.1.3/phpMyAdmin-5.1.3-all-languages.tar.gz"
	- install phpMyAdmin 5.1.3
	- make phpMyAdmin accessible with the "http://127.0.0.1/pma-subdir" url
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

	grep -i $username /etc/passwd > /dev/null

	if [ "$?" == "1" ]; then
		echo "error: the username $username does not exist"
		exit 1
	fi

	cat <<-EOT
	USERNAME: $username
	DBA_USERNAME: $dba_username
	PMA_SUBDIRECTORY: $pma_subdirectory
	PMA_VERSION: $pma_version

	EOT

	read -p "Press [y/Y] to confirm: " answer
	echo ""

	if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
		echo "canceled"
		exit
	fi
fi

# set phpX.Y version
php_version="8.2"

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

# check if phpmyadmin is not already installed
if [ -d /usr/share/phpmyadmin ]; then
	echo "error: phpMyAdmin is already installed in directory '/usr/share/phpmyadmin'"
	exit 1
fi

# check if pwgen is installed
if ! [ -x "$(command -v pwgen)" ]; then
	# pwgen is not installed
	sudo apt install pwgen
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
echo "$dba_username's phpmyadmin password"
echo -n "New password: "
read -s password
echo ""
echo -n "Re-type new password: "
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
# Alias /pma-subdir /usr/share/phpmyadmin
sudo sed -i "s/{pma_subdirectory}/$pma_subdirectory/g" /etc/apache2/conf-available/phpmyadmin.conf

# create phpmyadmin dedicated php session directory
sudo mkdir /var/lib/php/sessions/phpmyadmin

# set appropriate rights (drwx-wx-wt) on the phpmyadmin dedicated php sessions directory
sudo chmod 1733 /var/lib/php/sessions/phpmyadmin

# copy template-pool.conf to php fpm pool directory
sudo cp phpmyadmin-pool.conf /etc/php/$php_version/fpm/pool.d/phpmyadmin.conf

# edit file to match selected username
sudo sed -i "s/{username}/$username/" /etc/php/$php_version/fpm/pool.d/phpmyadmin.conf

# restart php fpm
sudo systemctl restart php$php_version-fpm.service

# enable phpmyadmin conf
sudo a2enconf phpmyadmin.conf

# restart apache2
sudo systemctl reload apache2.service

# inform user
echo "INFO: apache2 has been reloaded"

# create phpmyadmin tables
sudo mariadb < /usr/share/phpmyadmin/sql/create_tables.sql

# grant required privileges to pma account and set password
echo "GRANT SELECT, INSERT, UPDATE, DELETE ON phpmyadmin.* TO 'pma'@'localhost' IDENTIFIED BY '$pmapass';" | sudo mysql

# grant required privileges to phpmyadmin database administrator account and set password
echo "GRANT ALL PRIVILEGES ON *.* TO '$dba_username'@'localhost' IDENTIFIED BY '$password' WITH GRANT OPTION;" | sudo mysql
echo "FLUSH PRIVILEGES;" | sudo mysql

