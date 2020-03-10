#!/bin/bash

apt install -y fail2ban
apt install -y ufw
ufw enable
ufw allow OpenSSH
ufw allow "WWW Full"

