#!/bin/bash

echo "This script installs nvm"
echo ""
echo "Are you sure you want to continue?"
read -p "Press [y/Y] to confirm: " answer
echo ""

if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
	echo "canceled"
	exit
fi

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.2/install.sh | bash
echo "open a new terminal and type 'command -v nvm' to test the installation"

