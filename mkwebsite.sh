#!/bin/bash

function usage {
	this=$(basename $0)
	cat <<-EOT
	Usage: $this [USERNAME] [PROJECTS_DIRECTORY] [VHOST_DIRECTORY] [DOMAIN] [VHOST_TEMPLATE]

	This script configures a new website.
	It configures the Apache2 virtual host and the PHP-FPM pool files.

	Warning: this script will stop before doing anything if:

	- the specified PROJECTS_DIRECTORY does not exist
	- the specified VHOST_DIRECTORY already exists
	- the specified VHOST_TEMPLATE file does not exist

	USERNAME should be your username.
	PROJECTS_DIRECTORY is the directory in which you'll store all your projects.
	VHOST_DIRECTORY is the directory in which a particular project will be stored.
	DOMAIN is the domain name you will be using in your web browser to access a particular project.
	  This value is also used to set the sender email domain when sending mails
	VHOST_TEMPLATE is an optional parameter that specifies the Apache2 virtual host template you want to use for a particular project.
	  Possible values are: template-vhost.conf, template-vhost-symfony.conf, template-subdir.conf, template-subdir-symfony.conf
	  template-vhost*.conf files will create a new virtual host.
	  Creating a new virtual host is useful when you have a domain name and you want to separate your applications into different directories and memory space.
	  template-subdir*.conf files will create a new sub-directory.
	  Creating a new sub-directory is useful when you do not have a domain name but still want to separate applications into different directories and memory space.
	  Default value is "template-vhost.conf".

	WARNING: when using the templates "template-subdir.conf" or "template-subdir-symfony.conf", the DOMAIN parameter will be ignored, so any value is valid.

	Example 1: $this johndoe projects foo foo.local

	This command will:

	- make the website accessible from the url "http://foo.local"
	- use the default "template-vhost.conf" for the VHOST_TEMPLATE value
	- create the Apache2 virtual host file "/etc/apache2/sites-available/foo.conf"
	- create the PHP-FPM pool file "/etc/php/X.Y/fpm/pool.d/foo.conf"

	Example 2: $this johndoe projects foo foo.example.com

	This command will:

	- the same things as example 1
	- but make the website accessible from the url "http://foo.example.com"

	Example 3: $this johndoe projects foo foo.local template-vhost-symfony.conf

	This command will:

	- make the website accessible from the url "http://foo.local"
	- use the template "template-vhost-symfony.conf" for the VHOST_TEMPLATE value
	- create the Apache2 virtual host file "/etc/apache2/sites-available/example.conf"
	- create the PHP-FPM pool file "/etc/php/X.Y/fpm/pool.d/example.conf"

	Example 4: $this johndoe projects foo foo.example.com template-vhost-symfony.conf

	This command will:

	- the same things as example 3
	- but make the website accessible from the url "http://foo.example.com"

	Example 5: $this johndoe projects foo foo.local template-subdir.conf

	This command will:

	- ignore the domain "foo.local" parameter
	- make the website accessible from the url "http://localhost/foo", "http://example.com/foo" or "http://1.2.3.4/foo" depending on wether you are on a local machine, a vps and if you have a domain name or not.
	- use the template "template-subdir.conf" for the VHOST_TEMPLATE value
	- create the Apache2 conf file "/etc/apache2/sites-available/foo.conf"
	- create the PHP-FPM pool file "/etc/php/X.Y/fpm/pool.d/foo.conf"

	Example 6: $this johndoe projects foo foo.local template-subdir-symfony.conf

	This command will:

	- ignore the domain "foo.local" parameter
	- make the website accessible from the url "http://localhost/foo", "http://example.com/foo" or "http://1.2.3.4/foo" depending on wether you are on a local machine, a vps and if you have a domain name or not.
	- use the template "template-subdir-symfony.conf" for the VHOST_TEMPLATE value
	- create the Apache2 conf file "/etc/apache2/sites-available/example.conf"
	- create the PHP-FPM pool file "/etc/php/X.Y/fpm/pool.d/example.conf"

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
	domain="$4"

	grep -i $username /etc/passwd

	if [ "$?" == "1" ]; then
		echo "error: the username $username does not exists"
		exit 1
	fi

	if [ $# -gt 4 ]; then
		vhost_template="$5"

		if [ ! -f $vhost_template ]; then
			echo "error: the vhost template file '$vhost_template' does not exist"
			exit 1
		fi
	else
		vhost_template="template-vhost.conf"
	fi

	if [ "$vhost_template" == "template-subdir.conf" ] || [ "$vhost_template" == "template-subdir-symfony.conf" ]; then
		domain="<ignored>"
	fi

	cat <<-EOT
	USERNAME: $username
	PROJECTS_DIRECTORY: $projects_directory
	VHOST_DIRECTORY: $vhost_directory
	DOMAIN: $domain
	VHOST_TEMPLATE: $vhost_template

	EOT

	read -p "Press [y/Y] to confirm: " answer
	echo ""

	if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
		echo "canceled"
		exit
	fi
fi

# set phpX.Y version
php_version="7.4"

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

if [ ! -d /home/$username/$projects_directory ]; then
	echo "error: the projects directory '/home/$username/$projects_directory' does not exist"
	exit 1
fi

# create a dedicated php session directory
sudo mkdir /var/lib/php/sessions/$vhost_directory

# set appropriate rights (drwx-wx-wt) on the dedicated php sessions directory
sudo chmod 1733 /var/lib/php/sessions/$vhost_directory

# copy template-pool.conf to php fpm pool directory
sudo cp template-pool.conf /etc/php/$php_version/fpm/pool.d/$vhost_directory.conf

# edit file to match selected username and virtual host directory
sudo sed -i "s/{username}/$username/g" /etc/php/$php_version/fpm/pool.d/$vhost_directory.conf
sudo sed -i "s/{projects_directory}/$projects_directory/g" /etc/php/$php_version/fpm/pool.d/$vhost_directory.conf
sudo sed -i "s/{vhost_directory}/$vhost_directory/g" /etc/php/$php_version/fpm/pool.d/$vhost_directory.conf
sudo sed -i "s/{domain}/$domain/g" /etc/php/$php_version/fpm/pool.d/$vhost_directory.conf

# restart php fpm
sudo systemctl restart php$php_version-fpm.service

# copy template-vhost.conf to apache2 available virtual host directory
sudo cp $vhost_template /etc/apache2/sites-available/$vhost_directory.conf

# edit file to match selected username, projects directory, virtual host directory and local domain name
sudo sed -i "s/{username}/$username/g" /etc/apache2/sites-available/$vhost_directory.conf
sudo sed -i "s/{projects_directory}/$projects_directory/g" /etc/apache2/sites-available/$vhost_directory.conf
sudo sed -i "s/{vhost_directory}/$vhost_directory/g" /etc/apache2/sites-available/$vhost_directory.conf
sudo sed -i "s/{domain}/$domain/g" /etc/apache2/sites-available/$vhost_directory.conf

# enable virtual host
sudo a2ensite $vhost_directory.conf

# restart apache2
sudo systemctl reload apache2.service

# inform user
echo "apache2 reloaded"

