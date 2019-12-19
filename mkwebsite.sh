# @todo move editing of /etc/hosts to another script

username="popschool"
projects_directory="projects"
vhost_directory="foo"
local_domain="foo.local"

vhost_template="template-vhost.conf"
# vhost_template="template-vhost-symfony.conf"

if [ ! -d /home/$username/$projects_directory ]; then
	echo "error: the projects directory '/home/$username/$projects_directory' does not exist"
	exit
fi

if [ -d /home/$username/$projects_directory/$vhost_directory ]; then
	echo "error: vhost directory '/home/$username/$projects_directory/$vhost_directory' already exists"
	exit
fi

# create default virtual host directory
mkdir -p /home/$username/$projects_directory/$vhost_directory

# create default virtual host home page
echo "<?php" > /home/$username/$projects_directory/$vhost_directory/index.php
echo "echo 'OK $vhost_directory';" >> /home/$username/$projects_directory/$vhost_directory/index.php

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

# backup /etc/hosts file
if [ ! -f /etc/hosts.orig ]; then
	# backup original hosts file
	sudo cp /etc/hosts /etc/hosts.orig
else
	# get timestamp
	timestamp=$(date "+%Y%m%d%H%M%S")

	# backup /etc/hosts file with a timestamp
	sudo cp /etc/hosts /etc/hosts-$timestamp
fi

# add domain name to /etc/hosts file
sudo sed -i "s/\\(127\\.0\\.0\\.1\\s\\+.*\\)/\\1 $local_domain/" /etc/hosts
