#!/bin/bash

# check that the script is not run as root
current_id="$(id -nu)"

if [ "$current_id" == "root" ]; then
	echo "this script should not be run as root"
	exit 1
fi

# check that user is a sudoer
sudo_id=$(sudo id -nu)

if [ "$sudo_id" != "root" ]; then
	echo "you must be a sudoer to use this script"
	exit 1
fi

# install gromit-mpx
sudo apt install -y gromit-mpx

# install obs
sudo apt install -y obs-studio

# @info no need to download gnome bDMZ cursor theme
# @info gnome bDMZ cursor theme is shipped with the repo

# install gnome bDMZT cursor theme
tar -xzf ./160115-bDMZT.tar.gz -C ./
if [ ! -d "/usr/share/icons/bbDMZ" ]; then
	sudo mv bDMZT/bbDMZ /usr/share/icons/
fi
rm -r bDMZT/

