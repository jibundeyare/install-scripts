#!/bin/bash

echo "This script installs pip (the python package manager)"
echo ""
echo "Are you sure you want to continue?"
read -p "Press [y/Y] to confirm: " answer
echo ""

if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
	echo "canceled"
	exit
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

sudo apt install -y python3-dev python3-pip python3-venv
sudo ln -s python3 /usr/bin/python

