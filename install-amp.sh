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

	Example: $this johndoe projects www

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

	cat <<-EOT
	USERNAME: $username
	PROJECTS_DIRECTORY: $projects_directory
	DEFAULT_VHOST_DIRECTORY: $default_vhost_directory
	DOMAIN: $domain

	EOT

	read -p "Press [y/Y] to confirm: " -n 1 answer
	echo ""

	if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
		echo "canceled"
		exit
	fi
fi

# add php 7.4 repo
# wget -q https://packages.sury.org/php/apt.gpg -O- | sudo apt-key add -
wget -O php.gpg https://packages.sury.org/php/apt.gpg
sudo mv php.gpg /etc/apt/trusted.gpg.d/
echo "deb https://packages.sury.org/php/ buster main" | sudo tee /etc/apt/sources.list.d/php.list

# update debian
sudo apt update
sudo apt upgrade -y

# install apache2
sudo apt install -y apache2

# install mariadb (previously mysql)
sudo apt install -y mariadb-client mariadb-server

# install php7.4
sudo apt install -y imagemagick libapache2-mod-php7.4 php7.4 php7.4-cli php7.4-common php7.4-curl php7.4-fpm php7.4-imagick php7.4-json php7.4-mbstring php7.4-mysql php7.4-opcache php7.4-phpdbg php7.4-readline php7.4-xml php7.4-zip

# configure php7.4

# php7.4 configuration must be done once for each file
# /etc/php/7.4/apache2/php.ini
# /etc/php/7.4/cli/php.ini
# /etc/php/7.4/fpm/php.ini

# backup current config
if [ ! -f /etc/php/7.4/apache2/php.ini.orig ]; then
	sudo mv /etc/php/7.4/apache2/php.ini /etc/php/7.4/apache2/php.ini.orig
fi
if [ ! -f /etc/php/7.4/cli/php.ini.orig ]; then
	sudo mv /etc/php/7.4/cli/php.ini /etc/php/7.4/cli/php.ini.orig
fi
if [ ! -f /etc/php/7.4/fpm/php.ini.orig ]; then
	sudo mv /etc/php/7.4/fpm/php.ini /etc/php/7.4/fpm/php.ini.orig
fi

# configure time zone, log size, form upload max data size and form upload max data size
# date.timezone = Europe/Paris
# log_errors_max_len = 0
# upload_max_filesize = 32M
# post_max_size = 32M
#
# copy template-*-php.ini to php directory
sudo cp template-apache2-php.ini /etc/php/7.4/apache2/php.ini
sudo cp template-cli-php.ini /etc/php/7.4/cli/php.ini
sudo cp template-fpm-php.ini /etc/php/7.4/fpm/php.ini

# configure apache2

# general settings
sudo a2enmod headers
sudo a2enmod setenvif
sudo a2enmod rewrite

# disable php mod
sudo a2dismod php7.4
sudo a2dismod mpm_prefork

# enable php fpm
sudo a2enmod mpm_event
sudo a2enconf php7.4-fpm
sudo a2enmod proxy_fcgi

# backup current config
if [ ! -f /etc/apache2/apache2.conf.orig ]; then
	sudo mv /etc/apache2/apache2.conf /etc/apache2/apache2.conf.orig
fi

# copy template-apache2.conf to apache2 directory
sudo cp template-apache2.conf /etc/apache2/apache2.conf

# edit file to match selected username and projects directory
sudo sed -i "s/{username}/$username/g" /etc/apache2/apache2.conf
sudo sed -i "s/{projects_directory}/$projects_directory/g" /etc/apache2/apache2.conf

# configure php fpm

# backup current config
if [ ! -f /etc/php/7.4/fpm/pool.d/www.conf.orig ]; then
	sudo mv /etc/php/7.4/fpm/pool.d/www.conf /etc/php/7.4/fpm/pool.d/www.conf.orig
fi

# copy template-pool.conf to php fpm pool directory
sudo cp template-pool.conf /etc/php/7.4/fpm/pool.d/$default_vhost_directory.conf

# edit file to match selected username and virtual host directory
sudo sed -i "s/{username}/$username/g" /etc/php/7.4/fpm/pool.d/$default_vhost_directory.conf
sudo sed -i "s/{vhost_directory}/$default_vhost_directory/g" /etc/php/7.4/fpm/pool.d/$default_vhost_directory.conf
sudo sed -i "s/{domain}/$domain/g" /etc/php/7.4/fpm/pool.d/$default_vhost_directory.conf

# configure apache2 virtual host

# backup current config
if [ ! -f /etc/apache2/sites-available/000-default.conf.orig ]; then
	sudo cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf.orig
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

# restart php fpm
sudo systemctl restart php7.4-fpm.service

# restart apache2
sudo systemctl restart apache2.service

# inform user
echo "apache2 restarted"

