#!/bin/bash

# settings
vhost_directory="foo"

# disable vhost
sudo a2dissite $vhost_directory

# remove vhost config from apache2 available vhost directory
sudo rm /etc/apache2/sites-available/$vhost_directory.conf

# restart apache2
sudo systemctl restart apache2.service

# remove pool config from php fpm pool directory
sudo rm /etc/php/7.3/fpm/pool.d/$vhost_directory.conf

# restart php fpm
sudo systemctl restart php7.3-fpm.service
