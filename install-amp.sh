#!/bin/bash

function usage {
	this=$(basename $0)
	cat <<-EOT
	Usage: $this [USERNAME] [PROJECTS_DIRECTORY] [DEFAULT_VHOST_DIRECTORY] [DOMAIN]

	This script installs apache2, mariadb, php7 and php-fpm.
	The script modifies the default configuration of apache2 and php7.
	The script modifies the default virtual host and php-fpm pool:
	- the user's PROJECTS_DIRECTORY is whitelisted
	- the default virtual host is set to PROJECTS_DIRECTORY/DEFAULT_VHOST_DIRECTORY
	- the default virtual host is set to work with php-fpm

	USERNAME should be your username.
	PROJECTS_DIRECTORY is the directory in which you'll store all your projects.
	DEFAULT_VHOST_DIRECTORY is the directory containing the default website.
	DOMAIN is the domain name you will be using in your web browser to access a particular project.
	  This value is also used to set the sender email domain when sending mails

	Example: $this johndoe projects www localhost

	This command will :

	- set "johndoe" as the user for apache2 and php-fpm.
	- create the directory "/home/johndoe/projects"
	- create the directory "/home/johndoe/projects/www"
	EOT
}

if [ $# -lt 4 ]; then
	usage
	exit 1
else
	# settings
	username="$1"
	projects_directory="$2"
	default_vhost_directory="$3"
	domain="$4"

	grep -i $username /etc/passwd > /dev/null

	if [ "$?" == "1" ]; then
		echo "error: the username $username does not exist"
		exit 1
	fi

	cat <<-EOT
	USERNAME: $username
	PROJECTS_DIRECTORY: $projects_directory
	DEFAULT_VHOST_DIRECTORY: $default_vhost_directory
	DOMAIN: $domain

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

# find which distribution is installed
distribution="$(awk -F= '/^ID=/{print $2}' /etc/os-release)"

if [ "$distribution" == "debian" ]; then
	echo "info: you are using debian"
elif [ "$distribution" == "ubuntu" ]; then
	echo "info: you are using ubuntu"
else
	# distribution is not debian nor ubuntu
	echo "error: this script supports debian or ubuntu only"
	exit 1
fi

# add custom php repo
if [ "$distribution" == "debian" ]; then
	# wget -q https://packages.sury.org/php/apt.gpg -O- | sudo apt-key add -
	wget -O php.gpg https://packages.sury.org/php/apt.gpg
	sudo mv php.gpg /etc/apt/trusted.gpg.d/
	echo "deb https://packages.sury.org/php/ bullseye main" | sudo tee /etc/apt/sources.list.d/php.list
elif [ "$distribution" == "ubuntu" ]; then
	sudo add-apt-repository -y ppa:ondrej/php
	# add custom apache2 repo
	# @info this repo is advised by ppa:ondrej/php
	sudo add-apt-repository -y ppa:ondrej/apache2
fi

# set phpX.Y version
php_version="8.1"

# update debian
sudo apt update
sudo apt upgrade -y

# install apache2
sudo apt install -y apache2

# install mariadb (previously mysql)
sudo apt install -y mariadb-client mariadb-server

# install phpX.Y
sudo apt install -y imagemagick libapache2-mod-php$php_version php$php_version php$php_version-cli php$php_version-common php$php_version-curl php$php_version-fpm php$php_version-gd php$php_version-imagick php$php_version-mbstring php$php_version-mysql php$php_version-opcache php$php_version-phpdbg php$php_version-readline php$php_version-soap php$php_version-xml php$php_version-xmlrpc php$php_version-zip

# configure phpX.Y

# phpX.Y configuration must be done once for each file
# /etc/php/X.Y/apache2/php.ini
# /etc/php/X.Y/cli/php.ini
# /etc/php/X.Y/fpm/php.ini

# backup current config
if [ ! -f /etc/php/$php_version/apache2/php.ini.orig ]; then
	sudo mv /etc/php/$php_version/apache2/php.ini /etc/php/$php_version/apache2/php.ini.orig
fi
if [ ! -f /etc/php/$php_version/cli/php.ini.orig ]; then
	sudo mv /etc/php/$php_version/cli/php.ini /etc/php/$php_version/cli/php.ini.orig
fi
if [ ! -f /etc/php/$php_version/fpm/php.ini.orig ]; then
	sudo mv /etc/php/$php_version/fpm/php.ini /etc/php/$php_version/fpm/php.ini.orig
fi

# configure time zone, log size, form upload max data size and form upload max data size
# date.timezone = Europe/Paris
# log_errors_max_len = 0
# upload_max_filesize = 32M
# post_max_size = 32M
#
# copy template-*-php.ini to php directory
sudo cp template-apache2-php.ini /etc/php/$php_version/apache2/php.ini
sudo cp template-cli-php.ini /etc/php/$php_version/cli/php.ini
sudo cp template-fpm-php.ini /etc/php/$php_version/fpm/php.ini

# configure apache2

# general settings
sudo a2enmod headers
sudo a2enmod setenvif
sudo a2enmod rewrite

# disable php mod
sudo a2dismod php$php_version
sudo a2dismod mpm_prefork

# enable php fpm
sudo a2enmod mpm_event
sudo a2enconf php$php_version-fpm
sudo a2enmod proxy_fcgi

# backup current config
if [ ! -f /etc/apache2/apache2.conf.orig ]; then
	sudo mv /etc/apache2/apache2.conf /etc/apache2/apache2.conf.orig
fi

if [ ! -f /etc/apache2/conf-available/security.conf.orig ]; then
	sudo mv /etc/apache2/conf-available/security.conf /etc/apache2/conf-available/security.conf.orig
fi

# copy template-apache2.conf to apache2 directory
sudo cp template-apache2.conf /etc/apache2/apache2.conf

# edit file to match selected username and projects directory
sudo sed -i "s/{username}/$username/g" /etc/apache2/apache2.conf
sudo sed -i "s/{projects_directory}/$projects_directory/g" /etc/apache2/apache2.conf

# copy template-apache2-security.conf to apache2 directory
sudo cp template-apache2-security.conf /etc/apache2/conf-available/security.conf

# configure php fpm

# backup current config
if [ ! -f /etc/php/$php_version/fpm/pool.d/www.conf.orig ]; then
	sudo mv /etc/php/$php_version/fpm/pool.d/www.conf /etc/php/$php_version/fpm/pool.d/www.conf.orig
fi

# copy template-pool.conf to php fpm pool directory
sudo cp template-pool.conf /etc/php/$php_version/fpm/pool.d/$default_vhost_directory.conf

# edit file to match selected username, projects directory, virtual host directory and local domain name
sudo sed -i "s/{username}/$username/g" /etc/php/$php_version/fpm/pool.d/$default_vhost_directory.conf
sudo sed -i "s/{projects_directory}/$projects_directory/g" /etc/php/$php_version/fpm/pool.d/$default_vhost_directory.conf
sudo sed -i "s/{vhost_directory}/$default_vhost_directory/g" /etc/php/$php_version/fpm/pool.d/$default_vhost_directory.conf
sudo sed -i "s/{domain}/$domain/g" /etc/php/$php_version/fpm/pool.d/$default_vhost_directory.conf

# configure apache2 virtual host

# backup current config
if [ ! -f /etc/apache2/sites-available/000-default.conf.orig ]; then
	sudo mv /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf.orig
fi

# copy template-000-default.conf to apache2 available virtual host directory
sudo cp template-000-default.conf /etc/apache2/sites-available/000-default.conf

# edit file to match selected username, projects directory, virtual host directory and local domain name
sudo sed -i "s/{username}/$username/g" /etc/apache2/sites-available/000-default.conf
sudo sed -i "s/{projects_directory}/$projects_directory/g" /etc/apache2/sites-available/000-default.conf
sudo sed -i "s/{vhost_directory}/$default_vhost_directory/g" /etc/apache2/sites-available/000-default.conf
sudo sed -i "s/{domain}/$domain/g" /etc/apache2/sites-available/000-default.conf

# create default virtual host dedicated php session directory
sudo mkdir /var/lib/php/sessions/$default_vhost_directory

# set appropriate rights on the default virtual host dedicated php sessions directory
sudo chmod 1733 /var/lib/php/sessions/$default_vhost_directory

# create default virtual host directory
mkdir -p /home/$username/$projects_directory/$default_vhost_directory

# copy template-index.php to virtual host directory
sudo cp template-index.php /home/$username/$projects_directory/$default_vhost_directory/index.php

# edit file to match selected virtual host directory
sudo sed -i "s/{vhost_directory}/$default_vhost_directory/g" /home/$username/$projects_directory/$default_vhost_directory/index.php

# set the projects directory permissions
sudo chown -R $username:$username /home/$username/$projects_directory
sudo find /home/$username/$projects_directory -type d -exec chmod 755 {} \;
sudo find /home/$username/$projects_directory -type f -exec chmod 644 {} \;

# restart php fpm
sudo systemctl restart php$php_version-fpm.service

# restart apache2
sudo systemctl restart apache2.service

# inform user
echo "INFO: apache2 has been reloaded"

