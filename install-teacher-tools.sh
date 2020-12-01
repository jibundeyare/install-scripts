#!/bin/bash

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

