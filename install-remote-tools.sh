#!/bin/bash

# download teamviewer
if [ ! -f "teamviewer_amd64.deb" ]; then
	wget "https://download.teamviewer.com/download/linux/teamviewer_amd64.deb"
fi

# install teamviewer
sudo apt install -y ./teamviewer_amd64.deb

# download anydesk
anydesk_version="6.0.1-1"
if [ ! -f "anydesk_${anydesk_version}_amd64.deb" ]; then
	wget "https://download.anydesk.com/linux/anydesk_${anydesk_version}_amd64.deb"
fi

# install anydesk
sudo apt install -y ./anydesk_${anydesk_version}_amd64.deb

# disable wayland for teamviewer (and probably anydesk also)
# @warning this needs a restart of the graphical interface
sudo sed -i "s/#WaylandEnable=false/WaylandEnable=false/g" /etc/gdm3/daemon.conf

# inform user
echo "INFO: in order to be able to use teamviewer, wayland has been disabled in favor of xorg"
echo "WARNING: please be aware that the graphical interface must be restarted for this change to take effect"
