# @todo move editing of /etc/hosts to another script

vhost_directory="foo"
local_domain="foo.local"

# remove domain name from /etc/hosts file
sudo sed -i "s/ $local_domain//" /etc/hosts

# get timestamp
timestamp=$(date "+%Y%m%d%H%M%S")

# backup /etc/hosts file with a timestamp
sudo cp /etc/hosts /etc/hosts-$timestamp

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
