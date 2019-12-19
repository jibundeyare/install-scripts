#!/bin/bash

# this script resets the http authentication password

# settings
http_auth_username="johndoe"

# ask user confirmation
echo "Resetting the PhpMyAdmin HTTP authentication password"
read -p "Are tou sure you want to continue ? [y/N]: " answer

continue_operations="n"

if [ "$answer" == "Y" ] || [ "$answer" == "y" ]; then
	continue_operations="y"
fi

if [ $continue_operations == "n" ]; then
	echo "Canceled"
	exit
fi

# create http authentication password
echo "HTTP authentication password for login '$http_auth_username'"
sudo htpasswd -c /etc/phpmyadmin/htpasswd.login $http_auth_username

