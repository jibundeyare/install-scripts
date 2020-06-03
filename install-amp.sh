#!/bin/bash

function usage {
	this=$(basename $0)
	cat <<-EOT
	Usage: $this [USERNAME] [PROJECTS_DIRECTORY] [DEFAULT_VHOST_DIRECTORY]

	This script installs apache2, mariadb, php7 and php-fpm.
	The script modifies the default configuration of apache2 and php7.
	The script modifies the default vhost and php-fpm pool:
	- the "www-data" is replaced with the USERNAME value
	- the user's PROJECTS_DIRECTORY is whitelisted
	- the default vhost is set to PROJECTS_DIRECTORY/DEFAULT_VHOST_DIRECTORY
	- the default vhost is set to work with php-fpm

	USERNAME should be your username.
	PROJECTS_DIRECTORY is the directory in which you'll store all your projects.
	DEFAULT_VHOST_DIRECTORY is the directory containing the default website.

	Example: $this johndoe projects www

	This command will :

	- set "johndoe" as the user for apache2 and php-fpm.
	- create the directory "/home/johndoe/projects"
	- create the directory "/home/johndoe/projects/www"
	EOT
}

if [ $# -lt 3 ]; then
	usage
	exit 1
else
	# settings
	username="$1"
	projects_directory="$2"
	default_vhost_directory="$3"

	cat <<-EOT
	USERNAME: $username
	PROJECTS_DIRECTORY: $projects_directory
	DEFAULT_VHOST_DIRECTORY: $default_vhost_directory

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

# restore original files
sudo cp /etc/php/7.4/apache2/php.ini.orig /etc/php/7.4/apache2/php.ini
sudo cp /etc/php/7.4/cli/php.ini.orig /etc/php/7.4/cli/php.ini
sudo cp /etc/php/7.4/fpm/php.ini.orig /etc/php/7.4/fpm/php.ini

# configure time zone
# ;date.timezone =
# =>
# date.timezone = Europe/Paris
sudo sed -i "s/;date.timezone =/date.timezone = Europe\/Paris/" /etc/php/7.4/apache2/php.ini
sudo sed -i "s/;date.timezone =/date.timezone = Europe\/Paris/" /etc/php/7.4/cli/php.ini
sudo sed -i "s/;date.timezone =/date.timezone = Europe\/Paris/" /etc/php/7.4/fpm/php.ini

# configure log size
# log_errors_max_len = 1024
# =>
# log_errors_max_len = 0
sudo sed -i "s/log_errors_max_len = 1024/log_errors_max_len = 0/" /etc/php/7.4/apache2/php.ini
sudo sed -i "s/log_errors_max_len = 1024/log_errors_max_len = 0/" /etc/php/7.4/cli/php.ini
sudo sed -i "s/log_errors_max_len = 1024/log_errors_max_len = 0/" /etc/php/7.4/fpm/php.ini

# configure form upload max data size
# upload_max_filesize = 2M
# =>
# upload_max_filesize = 32M
sudo sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 32M/" /etc/php/7.4/apache2/php.ini
sudo sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 32M/" /etc/php/7.4/cli/php.ini
sudo sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 32M/" /etc/php/7.4/fpm/php.ini

# configure form upload max data size
# post_max_size = 8M
# =>
# post_max_size = 32M
sudo sed -i "s/post_max_size = 8M/post_max_size = 32M/" /etc/php/7.4/apache2/php.ini
sudo sed -i "s/post_max_size = 8M/post_max_size = 32M/" /etc/php/7.4/cli/php.ini
sudo sed -i "s/post_max_size = 8M/post_max_size = 32M/" /etc/php/7.4/fpm/php.ini

# configure apache2

# general settings
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
if [ ! -f /etc/apache2/envvars.orig ]; then
	sudo mv /etc/apache2/envvars /etc/apache2/envvars.orig
fi
if [ ! -f /etc/apache2/apache2.conf.orig ]; then
	sudo mv /etc/apache2/apache2.conf /etc/apache2/apache2.conf.orig
fi

# restore original files
sudo cp /etc/apache2/envvars.orig /etc/apache2/envvars
sudo cp /etc/apache2/apache2.conf.orig /etc/apache2/apache2.conf

# set user
# export APACHE_RUN_USER=www-data
# =>
# export APACHE_RUN_USER=popschool
sudo sed -i "s/export APACHE_RUN_USER=www-data/export APACHE_RUN_USER=$username/" /etc/apache2/envvars

# set group
# export APACHE_RUN_GROUP=www-data
# =>
# export APACHE_RUN_GROUP=popschool
sudo sed -i "s/export APACHE_RUN_GROUP=www-data/export APACHE_RUN_GROUP=$username/" /etc/apache2/envvars

# whitelist /home/popschool/projects document root directory
# <Directory /home/popschool/projects/>
#	Options Indexes FollowSymLinks
#	AllowOverride All
#	Require all granted
# </Directory>
#
count=$(grep "/home/$username/$projects_directory" /etc/apache2/apache2.conf | wc -l)
if [ $count -eq 0 ]; then
	sudo sed -i "182i\<Directory /home/$username/$projects_directory/>" /etc/apache2/apache2.conf
	sudo sed -i "183i\\\tOptions Indexes FollowSymLinks" /etc/apache2/apache2.conf
	sudo sed -i "184i\\\tAllowOverride All" /etc/apache2/apache2.conf
	sudo sed -i "185i\\\tRequire all granted" /etc/apache2/apache2.conf
	sudo sed -i "186i\</Directory>" /etc/apache2/apache2.conf
	sudo sed -i "187i\\\\" /etc/apache2/apache2.conf
fi

# configure php fpm

# backup current config
if [ ! -f /etc/php/7.4/fpm/pool.d/www.conf.orig ]; then
	sudo mv /etc/php/7.4/fpm/pool.d/www.conf /etc/php/7.4/fpm/pool.d/www.conf.orig
fi

# restore original file using default vhost directory name
sudo cp /etc/php/7.4/fpm/pool.d/www.conf.orig /etc/php/7.4/fpm/pool.d/$default_vhost_directory.conf

# set pool
# 'www'
# =>
# '$default_vhost_directory'
sudo sed -i "s/'www'/'$default_vhost_directory'/" /etc/php/7.4/fpm/pool.d/$default_vhost_directory.conf

# [www]
# =>
# [$default_vhost_directory]
sudo sed -i "s/\[www\]/[$default_vhost_directory]/" /etc/php/7.4/fpm/pool.d/$default_vhost_directory.conf

# set user
# user = www-data
# =>
# user = popschool
sudo sed -i "s/user = www-data/user = $username/" /etc/php/7.4/fpm/pool.d/$default_vhost_directory.conf

# set group
# group = www-data
# =>
# group = popschool
sudo sed -i "s/group = www-data/group = $username/" /etc/php/7.4/fpm/pool.d/$default_vhost_directory.conf

# set socket path
# listen = /run/php/php7.4-fpm.sock
# =>
# listen = /run/php/php7.4-fpm.$pool.sock
sudo sed -i "s/listen = \/run\/php\/php7.4-fpm.sock/listen = \/run\/php\/php7.4-fpm.\$pool.sock/" /etc/php/7.4/fpm/pool.d/$default_vhost_directory.conf

# set socket owner
# listen.owner = www-data
# =>
# listen.owner = popschool
sudo sed -i "s/listen.owner = www-data/listen.owner = $username/" /etc/php/7.4/fpm/pool.d/$default_vhost_directory.conf

# set socket group
# listen.group = www-data
# =>
# listen.group = popschool
sudo sed -i "s/listen.group = www-data/listen.group = $username/" /etc/php/7.4/fpm/pool.d/$default_vhost_directory.conf

# set log path
# ;php_admin_value[error_log] = /var/log/fpm-php.www.log
# =>
# php_admin_value[error_log] = /var/log/fpm-php.$pool.log
sudo sed -i "s/;php_admin_value\[error_log\] = \/var\/log\/fpm-php.www.log/php_admin_value[error_log] = \/var\/log\/fpm-php.\$pool.log/" /etc/php/7.4/fpm/pool.d/$default_vhost_directory.conf

# configure apache2 virtual host

# backup current config
if [ ! -f /etc/apache2/sites-available/000-default.conf.orig ]; then
	sudo cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf.orig
fi

# restore original file
sudo cp /etc/apache2/sites-available/000-default.conf.orig /etc/apache2/sites-available/000-default.conf

# set document root for default virtual host
# DocumentRoot /var/www/html
# =>
# DocumentRoot /home/popschool/projects/www
sudo sed -i "s/DocumentRoot \/var\/www\/html/DocumentRoot \/home\/$username\/$projects_directory\/$default_vhost_directory/" /etc/apache2/sites-available/000-default.conf

# add socket config to default virtual host
#
#	<IfModule proxy_fcgi_module>
#	<FilesMatch ".+\.ph(ar|p|tml)$">
#		SetHandler "proxy:unix:/run/php/php7.4-fpm.www.sock|fcgi://localhost"
#	</FilesMatch>
#	</IfModule>
count=$(grep "/run/php/php7.4-fpm.$default_vhost_directory.sock" /etc/apache2/sites-available/000-default.conf | wc -l)
if [ $count -eq 0 ]; then
	sudo sed -i "29i\\\\" /etc/apache2/sites-available/000-default.conf
	sudo sed -i "30i\\\t<IfModule proxy_fcgi_module>" /etc/apache2/sites-available/000-default.conf
	sudo sed -i "31i\\\t<FilesMatch \".+\\\.ph(ar|p|tml)\$\">" /etc/apache2/sites-available/000-default.conf
	sudo sed -i "32i\\\t\\tSetHandler \"proxy:unix:/run/php/php7.4-fpm.$default_vhost_directory.sock|fcgi://localhost\"" /etc/apache2/sites-available/000-default.conf
	sudo sed -i "33i\\\t</FilesMatch>" /etc/apache2/sites-available/000-default.conf
	sudo sed -i "34i\\\t</IfModule>" /etc/apache2/sites-available/000-default.conf
fi

# create default virtual host directory
mkdir -p /home/$username/$projects_directory/$default_vhost_directory

# create default virtual host home page
echo "<?php" > /home/$username/$projects_directory/$default_vhost_directory/index.php
echo "echo 'OK $default_vhost_directory';" >> /home/$username/$projects_directory/$default_vhost_directory/index.php

# restart php fpm
sudo systemctl restart php7.4-fpm.service

# restart apache2
sudo systemctl restart apache2.service

# inform user
echo "apache2 restarted"

