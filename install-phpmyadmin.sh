#!/bin/bash

# this script installs phpmyadmin
# the script adds http authentication to phpmyadmin
# it will ask you for first for an http authentication password
# and it will ask you for the phpmyadmin account password later

# settings
http_auth_username="johndoe"

# create http authentication password
if [ ! -f /etc/phpmyadmin/htpasswd.login ]; then
	echo "HTTP authentication password for login '$http_auth_username'"
	htpasswd -c ~/htpasswd.login $http_auth_username
fi

# install phpmyadmin
sudo apt install -y phpmyadmin

# grant all privileges to phpmyadmin account
echo "GRANT ALL PRIVILEGES ON *.* TO 'phpmyadmin'@'localhost' WITH GRANT OPTION;" | sudo mysql
echo "FLUSH PRIVILEGES;" | sudo mysql

# backup current config
if [ ! -f /etc/phpmyadmin/apache.conf.orig ]; then
	sudo cp /etc/phpmyadmin/apache.conf /etc/phpmyadmin/apache.conf.orig
fi

# enable phpmyadmin
sudo ln -s /etc/phpmyadmin/apache.conf /etc/apache2/conf-available/phpmyadmin.conf
sudo a2enconf phpmyadmin.conf

# enable http authentication password
if [ ! -f /etc/phpmyadmin/htpasswd.login ]; then
	sudo mv ~/htpasswd.login /etc/phpmyadmin/htpasswd.login
fi

# add http authentication
# AuthType Basic
# AuthName "phpMyAdmin"
# AuthUserFile /etc/phpmyadmin/htpasswd
# Require valid-user
#
count=$(grep "AuthUserFile /etc/phpmyadmin/htpasswd.login" /etc/phpmyadmin/apache.conf | wc -l)
if [ $count -eq 0 ]; then
	sudo sed -i "9i\AuthType Basic" /etc/phpmyadmin/apache.conf
	sudo sed -i "10i\AuthName \"phpMyAdmin\"" /etc/phpmyadmin/apache.conf
	sudo sed -i "11i\AuthUserFile /etc/phpmyadmin/htpasswd.login" /etc/phpmyadmin/apache.conf
	sudo sed -i "12i\Require valid-user" /etc/phpmyadmin/apache.conf
	sudo sed -i "13i\\\\" /etc/phpmyadmin/apache.conf
fi

# restart apache2
sudo systemctl restart apache2.service

