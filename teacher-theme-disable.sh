#!/bin/bash

# @info with debian 9, default cursor theme is 'Adwaita'

# set log file
log_file="teacher-theme.log"

default_cursor_theme=$(sed "s/default_cursor_theme: '\\([^']*\\)'/\1/" $log_file)

echo "reverting to gnome default cursor theme: '$default_cursor_theme'"

# revert to gnome default cursor theme
gsettings set org.gnome.desktop.interface cursor-theme '$default_cursor_theme'
gsettings set org.gnome.desktop.wm.preferences button-layout ':close'

# remove log file only if gnome default cursor theme was restored
active_cursor_theme="$(gsettings get org.gnome.desktop.interface cursor-theme)"

if [ "$active_cursor_theme" == "$default_cursor_theme" ]; then
	rm $log_file
fi

