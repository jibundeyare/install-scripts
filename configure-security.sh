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

	count=$(grep "$username" /etc/passwd | wc -l)
	if [ $count -eq 0 ]; then
		echo "error: username '$username' does not exist"
		exit 1
	fi

	cat <<-EOT
	USERNAME: $username
	SSH_PORT: $ssh_port

	WARNING: if the ssh port you have choosen is different from the one you are actualy connected with, the firewall will cut out the current connection.

	EOT

	read -p "Press [y/Y] to confirm: " -n 1 answer
	echo ""

	if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
		echo "canceled"
		exit
	fi
fi

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
# see /etc/services for list of services and tcp or udp type
sudo ufw allow http
sudo ufw allow https
sudo ufw allow $ssh_port/tcp

# enable ufw
sudo ufw enable

# display firewall status
sudo ufw status
