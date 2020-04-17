#!/bin/bash

echo "error: sorry, this script is currently unavailable"
exit 1

# @todo use cli parameters to get ssh port number
ssh_port="22"

# @todo configure sshd (no password for root, port number)

sudo apt install -y fail2ban

# @todo edit fail2ban config to use $ssh_port

sudo systemctl restart fail21ban

sudo apt install -y ufw
sudo ufw allow $ssh_port
sudo ufw allow 80
sudo ufw allow 443
sudo ufw status

# @todo warn before proceeding

sudo ufw enable

