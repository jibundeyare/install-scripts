#!/bin/bash

# enable gnome bDMZT cursor theme only if it's installed
if [ -d "/usr/share/icons/bbDMZ" ]; then
	gsettings set org.gnome.desktop.interface cursor-theme 'bbDMZ'
	gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,close'
fi

