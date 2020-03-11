#!/bin/bash

sudo apt install -y fail2ban
sudo apt install -y ufw
sudo ufw enable
sudo ufw allow OpenSSH
sudo ufw allow "WWW Full"
sudo ufw status

