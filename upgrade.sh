#!/bin/bash

default_vhost_directory="www"

sudo sed -i "s/#ServerName/ServerName/g" /etc/apache2/sites-available/000-default.conf
sudo mv /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/$default_vhost_directory.conf
sudo mv /etc/apache2/sites-available/000-default.conf.orig /etc/apache2/sites-available/000-default.conf
sudo rm /etc/apache2/sites-enabled/000-default.conf
sudo ln -s ../sites-available/$default_vhost_directory.conf /etc/apache2/sites-enabled/000-default.conf
sudo systemctl restart apache2.service

