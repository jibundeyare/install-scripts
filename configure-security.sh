#!/bin/bash

function usage {
	this=$(basename $0)
	cat <<-EOT
	Usage: $this [USERNAME] [SSH_PORT]

	This script does the following things:
	- configure ssh daemon to use a custom port
	- configure ssh daemon to disable login using password for root user
	- configure ssh daemon to disable login using password for all users, except the specified one
	- install fail2ban and configure it to use the specified ssh port
	- install ufw and configure it to use the http ports 80 and 443 and the specified ssh port

	USERNAME should be your username.
	SSH_PORT is the port number that will be used to connect to the server using ssh. Any number between 49152 and 65535 is fine.

	WARNING: please take time to note down the ssh port you have choosen. Otherwise you might need to get locked out of your own server.

	Example: $this johndoe 54321

	This command will :

	- let "johndoe" login with a password
	- disable password login for everyone else (including root)
	- make the ssh daemon listen on port 54321
	- make fail2ban daemon listen on port 54321
	- open the ssh port 54321 in the firewall
	- open the http ports 80 and 443 in the firewall
	EOT
}

if [ $# -lt 2 ]; then
	usage
	exit 1
else
	# settings
	username="$1"
	ssh_port="$2"

	if [ "$username" == "root" ]; then
		echo "error: username must be different from root"
		exit 1
	fi

	grep -i $username /etc/passwd > /dev/null

	if [ "$?" == "1" ]; then
		echo "error: the username $username does not exist"
		exit 1
	fi

	cat <<-EOT
	USERNAME: $username
	SSH_PORT: $ssh_port

	WARNING: if the ssh port you have choosen is different from the one you are actualy connected with, the firewall will cut out the current connection.

	EOT

	read -p "Press [y/Y] to confirm: " answer
	echo ""

	if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
		echo "canceled"
		exit
	fi
fi

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

# ask user for mariadb root password
echo ""
echo "mariadb root password"
echo -n "New password: "
read -s mariadb_root_password
echo ""
echo -n "Re-type new password: "
read -s mariadb_root_password2
echo ""
echo ""

if [ "$mariadb_root_password" != "$mariadb_root_password" ]; then
	echo "error: the mariadb root passwords did not match"
	exit 1
fi

# secure mariadb installation
sudo mariadb <<-EOT
UPDATE mysql.user SET Password=PASSWORD('$mariadb_root_password') WHERE User='root';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test_%';
FLUSH PRIVILEGES;
EOT

# install unattended upgrades
sudo apt-get install -y unattended-upgrades

# backup current unattended upgrades config
if [ ! -f /etc/apt/apt.conf.d/20auto-upgrades.orig ]; then
	sudo mv /etc/apt/apt.conf.d/20auto-upgrades /etc/apt/apt.conf.d/20auto-upgrades.orig
fi
if [ ! -f /etc/apt/apt.conf.d/50unattended-upgrades.orig ]; then
	sudo mv /etc/apt/apt.conf.d/50unattended-upgrades /etc/apt/apt.conf.d/50unattended-upgrades.orig
fi

# copy unattended config teplate to apt directory
sudo cp template-20auto-upgrades /etc/apt/apt.conf.d/20auto-upgrades
sudo cp template-50unattended-upgrades /etc/apt/apt.conf.d/50unattended-upgrades

# enable unattended upgrades
sudo systemctl enable unattended-upgrades.service

# start unattended upgrades
sudo systemctl start unattended-upgrades.service

# backup current sshd config
if [ ! -f /etc/ssh/sshd_config.orig ]; then
	sudo mv /etc/ssh/sshd_config /etc/ssh/sshd_config.orig
fi

# restore original config
sudo cp /etc/ssh/sshd_config.orig /etc/ssh/sshd_config

# configure sshd

# set port number
sudo sed -i "s/#Port 22/Port $ssh_port/" /etc/ssh/sshd_config

# remove any authentication method for root
sudo sed -i "/^\\s*PermitRootLogin .\\+/d" /etc/ssh/sshd_config
# remove any password authentication authorization for everyone
sudo sed -i "/^\\s*PasswordAuthentication .\\+/d" /etc/ssh/sshd_config

# disable password authentication for root
sudo sed -i "s/^#\\s*PermitRootLogin .\\+/PermitRootLogin prohibit-password/" /etc/ssh/sshd_config

# disable password authentication for everyone
sudo sed -i "s/^#\\s*PasswordAuthentication .\\+/PasswordAuthentication no/" /etc/ssh/sshd_config

# enable login with password for selected user only
sudo sed -i "$ a \\\\" /etc/ssh/sshd_config
sudo sed -i "$ a Match User $username" /etc/ssh/sshd_config
sudo sed -i "$ a \\\tPasswordAuthentication yes" /etc/ssh/sshd_config
sudo sed -i "$ a \\\\" /etc/ssh/sshd_config

# restart sshd
sudo systemctl restart sshd

# install fail2ban
sudo apt install -y fail2ban

# configure fail2ban

# copy fail2ban-jail.local to fail2ban config directory
sudo cp fail2ban-jail.local /etc/fail2ban/jail.local

# edit file to match selected ssh port
sudo sed -i "s/{ssh_port}/$ssh_port/g" /etc/fail2ban/jail.local

# restart fail2ban
sudo systemctl restart fail2ban

# install ufw
sudo apt install -y ufw

# configure ufw

# delete all rules
sudo ufw --force reset

# set open ports
# see /etc/services for list of services and tcp or udp type
sudo ufw allow http
sudo ufw allow https
sudo ufw allow $ssh_port/tcp

# enable ufw
sudo ufw --force enable

# display firewall status
sudo ufw status

