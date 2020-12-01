#!/bin/bash

# @info with debian 9, default cursor theme is 'Adwaita'

# set log file
log_file="teacher-theme.log"

# log gnome default cursor theme name
if [ ! -f "$log_file" ]; then
	default_cursor_theme="$(gsettings get org.gnome.desktop.interface cursor-theme)"
	echo "default_cursor_theme: $default_cursor_theme" > $log_file
fi

echo "customizing gnome:"
echo "- cursor theme"
echo "- windows manager button layout"

# enable gnome bDMZT cursor theme only if it's installed
if [ -d "/usr/share/icons/bbDMZ" ]; then
	gsettings set org.gnome.desktop.interface cursor-theme 'bbDMZ'
	gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,close'
fi

