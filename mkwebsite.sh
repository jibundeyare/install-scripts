#!/bin/bash

function usage {
	this=$(basename $0)
	cat <<-EOT
	Usage: $this [USERNAME] [PROJECTS_DIRECTORY] [VHOST_DIRECTORY] [LOCAL_DOMAIN] [VHOST_TEMPLATE]

	This script configures a new empty website.
	It creates a new directory in your projects directory, configures the Apache2 vhost and the PHP-FPM pool files and finaly creates a default PHP home page.

	Warning: this script will stop before doing anything if:

	- the specified PROJECTS_DIRECTORY does not exist
	- the specified VHOST_DIRECTORY already exists
	- the specified VHOST_TEMPLATE file does not exist

	USERNAME should be your username.
	PROJECTS_DIRECTORY is the directory in which you'll store all your projects.
	VHOST_DIRECTORY is the directory in which a particular project will be stored.
	LOCAL_DOMAIN is the domain name you will be using in your web browser to access a particular project.
	VHOST_TEMPLATE is an optional parameter that specifies the Apache2 vhost template you want to use for a particular project.
	  Possible values are: template-vhost.conf, template-vhost-symfony.conf
	  Default value is "template-vhost.conf".

	Example 1: $this johndoe projects foo foo.local

	This command will:

	- use the default "template-vhost.conf" for the VHOST_TEMPLATE value
	- create the project directory "/home/johndoe/projects/foo"
	- create a default PHP home page in the "/home/johndoe/projects/foo" directory
	- create the Apache2 vhost file "/etc/apache2/sites-available/foo.conf"
	- create the PHP-FPM pool file "/etc/php/7.3/fpm/pool.d/foo.conf"

	Example 2: $this johndoe projects example example.local template-vhost-symfony.conf

	This command will:

	- create the project directory "/home/johndoe/projects/example"
	- create the document root directory "/home/johndoe/projects/example/public"
	- create a default PHP home page in the "/home/johndoe/projects/example/public" directory
	- create the Apache2 vhost file "/etc/apache2/sites-available/example.conf"
	- create the PHP-FPM pool file "/etc/php/7.3/fpm/pool.d/example.conf"
	EOT
}

if [ $# -lt 4 ]; then
	usage
	exit 1
else
	# settings
	username="$1"
	projects_directory="$2"
	vhost_directory="$3"
	local_domain="$4"

	if [ $# -gt 4 ]; then
		vhost_template="$5"

		if [ ! -f $vhost_template ]; then
			echo "error: the vhost template file '$vhost_template' does not exist"
			exit
		fi
	else
		vhost_template="template-vhost.conf"
	fi

	cat <<-EOT
	USERNAME: $username
	PROJECTS_DIRECTORY: $projects_directory
	VHOST_DIRECTORY: $vhost_directory
	LOCAL_DOMAIN: $local_domain
	VHOST_TEMPLATE: $vhost_template

	EOT

	read -p "Press [y/Y] to confirm: " -n 1 answer
	echo ""

	if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
		echo "canceled"
		exit
	fi
fi

if [ ! -d /home/$username/$projects_directory ]; then
	echo "error: the projects directory '/home/$username/$projects_directory' does not exist"
	exit
fi

if [ -d /home/$username/$projects_directory/$vhost_directory ]; then
	echo "error: vhost directory '/home/$username/$projects_directory/$vhost_directory' already exists"
	exit
fi

# create virtual host directory
mkdir -p /home/$username/$projects_directory/$vhost_directory

# create a default home page
if [ "$vhost_template" == "template-vhost-symfony.conf" ]; then
	# create "public" document root directory
	mkdir -p /home/$username/$projects_directory/$vhost_directory/public
	# create the default home page in the "public" directory
	echo "<?php" > /home/$username/$projects_directory/$vhost_directory/public/index.php
	echo "echo 'OK $vhost_directory';" >> /home/$username/$projects_directory/$vhost_directory/public/index.php
else
	# create the default home page in the document root directory
	echo "<?php" > /home/$username/$projects_directory/$vhost_directory/index.php
	echo "echo 'OK $vhost_directory';" >> /home/$username/$projects_directory/$vhost_directory/index.php
fi

# copy template-pool.conf to php fpm pool directory
sudo cp template-pool.conf /etc/php/7.3/fpm/pool.d/$vhost_directory.conf

# edit file to match selected username and vhost directory
sudo sed -i "s/{username}/$username/" /etc/php/7.3/fpm/pool.d/$vhost_directory.conf
sudo sed -i "s/{vhost_directory}/$vhost_directory/" /etc/php/7.3/fpm/pool.d/$vhost_directory.conf

# restart php fpm
sudo systemctl restart php7.3-fpm.service

# copy template-vhost.conf to apache2 available vhost directory
sudo cp $vhost_template /etc/apache2/sites-available/$vhost_directory.conf

# edit file to match selected username, projects directory, vhost directory and local domain name
sudo sed -i "s/{username}/$username/" /etc/apache2/sites-available/$vhost_directory.conf
sudo sed -i "s/{projects_directory}/$projects_directory/" /etc/apache2/sites-available/$vhost_directory.conf
sudo sed -i "s/{vhost_directory}/$vhost_directory/" /etc/apache2/sites-available/$vhost_directory.conf
sudo sed -i "s/{local_domain}/$local_domain/" /etc/apache2/sites-available/$vhost_directory.conf

# enable vhost
sudo a2ensite $vhost_directory.conf

# restart apache2
sudo systemctl restart apache2.service

