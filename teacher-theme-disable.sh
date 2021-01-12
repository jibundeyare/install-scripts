#!/bin/bash

# @info with debian 9, default cursor theme is 'Adwaita'

# set lock file
lock_file="teacher-theme.lock"

if [ ! -f "$lock_file" ]; then
	echo "error: missing $lock_file. Default cursor theme is unknown."
	exit 1
fi

# get default cursor theme
default_cursor_theme=$(sed "s/default_cursor_theme: '\\([^']*\\)'/\1/" $lock_file)

echo "reverting to gnome default:"
echo "- cursor theme ('$default_cursor_theme')"
echo "- windows manager button layout"

# revert to gnome default cursor theme
gsettings set org.gnome.desktop.interface cursor-theme $default_cursor_theme
gsettings set org.gnome.desktop.wm.preferences button-layout ':close'

# remove lock file only if gnome default cursor theme was restored
active_cursor_theme="$(gsettings get org.gnome.desktop.interface cursor-theme)"

if [ "$active_cursor_theme" == "'$default_cursor_theme'" ]; then
	rm $lock_file
fi

