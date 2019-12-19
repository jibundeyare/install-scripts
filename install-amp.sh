# this script installs apache2, mariadb and php7
# the script modifies the default configuration of apache2 and php7
# the script does not add any new vhost or php-fpm pool, instead it modifies the default vhost and php-fpm pool

# add php 7.3 repo
wget -q https://packages.sury.org/php/apt.gpg -O- | sudo apt-key add -
# wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
echo "deb https://packages.sury.org/php/ stretch main" | sudo tee /etc/apt/sources.list.d/php.list

# update debian
sudo apt update
sudo apt upgrade -y

# install apt-transport-https
sudo apt install -y apt-transport-https

# install apache2
sudo apt install -y apache2

# install mariadb (previously mysql)
sudo apt install -y mariadb-client mariadb-server

# install php7.3
sudo apt install -y libapache2-mod-php7.3 php7.3 php7.3-cli php7.3-common php7.3-curl php7.3-fpm php7.3-json php7.3-mbstring php7.3-mysql php7.3-opcache php7.3-phpdbg php7.3-readline php7.3-xml php7.3-zip

# configure php7.3

# php7.3 configuration must be done once for each file
# /etc/php/7.3/apache2/php.ini
# /etc/php/7.3/cli/php.ini
# /etc/php/7.3/fpm/php.ini

# backup current config
sudo cp /etc/php/7.3/apache2/php.ini /etc/php/7.3/apache2/php.ini.orig
sudo cp /etc/php/7.3/cli/php.ini /etc/php/7.3/cli/php.ini.orig
sudo cp /etc/php/7.3/fpm/php.ini /etc/php/7.3/fpm/php.ini.orig

# configure time zone
# ;date.timezone =
# =>
# date.timezone = Europe/Paris
sudo sed -i "s/;date.timezone =/date.timezone = Europe\/Paris/" /etc/php/7.3/apache2/php.ini
sudo sed -i "s/;date.timezone =/date.timezone = Europe\/Paris/" /etc/php/7.3/cli/php.ini
sudo sed -i "s/;date.timezone =/date.timezone = Europe\/Paris/" /etc/php/7.3/fpm/php.ini

# configure log size
# log_errors_max_len = 1024
# =>
# log_errors_max_len = 0
sudo sed -i "s/log_errors_max_len = 1024/log_errors_max_len = 0/" /etc/php/7.3/apache2/php.ini
sudo sed -i "s/log_errors_max_len = 1024/log_errors_max_len = 0/" /etc/php/7.3/cli/php.ini
sudo sed -i "s/log_errors_max_len = 1024/log_errors_max_len = 0/" /etc/php/7.3/fpm/php.ini

# configure form upload max data size 
# upload_max_filesize = 2M
# =>
# upload_max_filesize = 32M
sudo sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 32M/" /etc/php/7.3/apache2/php.ini
sudo sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 32M/" /etc/php/7.3/cli/php.ini
sudo sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 32M/" /etc/php/7.3/fpm/php.ini

# configure form upload max data size 
# post_max_size = 8M
# =>
# post_max_size = 32M
sudo sed -i "s/post_max_size = 8M/post_max_size = 32M/" /etc/php/7.3/apache2/php.ini
sudo sed -i "s/post_max_size = 8M/post_max_size = 32M/" /etc/php/7.3/cli/php.ini
sudo sed -i "s/post_max_size = 8M/post_max_size = 32M/" /etc/php/7.3/fpm/php.ini

# configure apache2

# general settings
sudo a2enmod setenvif
sudo a2enmod rewrite

# disable php mod
sudo a2dismod php7.3
sudo a2dismod mpm_prefork

# enable php fpm
sudo a2enmod mpm_event
sudo a2enconf php7.3-fpm
sudo a2enmod proxy_fcgi

# backup current config
sudo cp /etc/apache2/envvars /etc/apache2/envvars.orig
sudo cp /etc/apache2/apache2.conf /etc/apache2/apache2.conf.orig

# set user
# export APACHE_RUN_USER=www-data
# =>
# export APACHE_RUN_USER=popschool
sudo sed -i "s/export APACHE_RUN_USER=www-data/export APACHE_RUN_USER=popschool/" /etc/apache2/envvars

# set group
# export APACHE_RUN_GROUP=www-data
# =>
# export APACHE_RUN_GROUP=popschool
sudo sed -i "s/export APACHE_RUN_GROUP=www-data/export APACHE_RUN_GROUP=popschool/" /etc/apache2/envvars

# whitelist /home/popschool/projects document root directory
# <Directory /home/popschool/projects/>
# 	Options Indexes FollowSymLinks
# 	AllowOverride All
# 	Require all granted
# </Directory>
#
sudo sed -i "182i\<Directory /home/popschool/projects/>" /etc/apache2/apache2.conf
sudo sed -i "183i\\\tOptions Indexes FollowSymLinks" /etc/apache2/apache2.conf
sudo sed -i "184i\\\tAllowOverride All" /etc/apache2/apache2.conf
sudo sed -i "185i\\\tRequire all granted" /etc/apache2/apache2.conf
sudo sed -i "186i\</Directory>" /etc/apache2/apache2.conf
sudo sed -i "187i\\\\" /etc/apache2/apache2.conf

# configure php fpm

# backup current config
# (copy original file to /root directory)
sudo cp /etc/php/7.3/fpm/pool.d/www.conf /root/php-7.3-fpm-pool.d-www.conf.orig

# set user
# user = www-data
# =>
# user = popschool
sudo sed -i "s/user = www-data/user = popschool/" /etc/php/7.3/fpm/pool.d/www.conf

# set group
# group = www-data
# =>
# group = popschool
sudo sed -i "s/group = www-data/group = popschool/" /etc/php/7.3/fpm/pool.d/www.conf

# set socket path
# listen = /run/php/php7.3-fpm.sock
# =>
# listen = /run/php/php7.3-fpm.$pool.sock
sudo sed -i "s/listen = \/run\/php\/php7.3-fpm.sock/listen = \/run\/php\/php7.3-fpm.\$pool.sock/" /etc/php/7.3/fpm/pool.d/www.conf

# set socket owner
# listen.owner = www-data
# =>
# listen.owner = popschool
sudo sed -i "s/listen.owner = www-data/listen.owner = popschool/" /etc/php/7.3/fpm/pool.d/www.conf

# set socket group
# listen.group = www-data
# =>
# listen.group = popschool
sudo sed -i "s/listen.group = www-data/listen.group = popschool/" /etc/php/7.3/fpm/pool.d/www.conf

# set log path
# ;php_admin_value[error_log] = /var/log/fpm-php.www.log
# =>
# php_admin_value[error_log] = /var/log/fpm-php.$pool.log
sudo sed -i "s/;php_admin_value\[error_log\] = \/var\/log\/fpm-php.www.log/php_admin_value[error_log] = \/var\/log\/fpm-php.\$pool.log/" /etc/php/7.3/fpm/pool.d/www.conf

# configure apache2 virtual host

# backup current config
sudo cp /etc/apache2/sites-available/000-default.conf 	/etc/apache2/sites-available/000-default.conf.orig

# set document root for default virtual host
# DocumentRoot /var/www/html
# =>
# DocumentRoot /home/popschool/projects/www
sudo sed -i "s/DocumentRoot \/var\/www\/html/DocumentRoot \/home\/popschool\/projects\/www/" /etc/apache2/sites-available/000-default.conf

# add socket config to default virtual host
#
# 	<IfModule !mod_php7.c>
# 	<IfModule proxy_fcgi_module>
# 	<FilesMatch ".+\.ph(ar|p|tml)$">
# 		SetHandler "proxy:unix:/run/php/php7.3-fpm.www.sock|fcgi://localhost"
# 	</FilesMatch>
# 	</IfModule>
# 	</IfModule>
sudo sed -i "29i\\\\" /etc/apache2/sites-available/000-default.conf
sudo sed -i "30i\\\t<IfModule \!mod_php7.c>" /etc/apache2/sites-available/000-default.conf
sudo sed -i "31i\\\t<IfModule proxy_fcgi_module>" /etc/apache2/sites-available/000-default.conf
sudo sed -i "32i\\\t<FilesMatch \".+\\\.ph(ar|p|tml)\$\">" /etc/apache2/sites-available/000-default.conf
sudo sed -i "33i\\\t\\tSetHandler \"proxy:unix:/run/php/php7.3-fpm.www.sock|fcgi://localhost\"" /etc/apache2/sites-available/000-default.conf
sudo sed -i "34i\\\t</FilesMatch>" /etc/apache2/sites-available/000-default.conf
sudo sed -i "35i\\\t</IfModule>" /etc/apache2/sites-available/000-default.conf
sudo sed -i "36i\\\t</IfModule>" /etc/apache2/sites-available/000-default.conf

# @todo install phpmyadmin
# @todo conf phpmyadmin

# create default virtual host directory
mkdir -p ~/projects/www

# create default virtual host home page
echo "<?php" > ~/projects/www/index.php
echo "phpinfo();" >> ~/projects/www/index.php

# restart php fpm
sudo systemctl restart php7.3-fpm.service

# restart apache2
sudo systemctl restart apache2.service

