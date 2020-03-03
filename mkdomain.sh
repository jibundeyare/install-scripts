#!/bin/bash

# settings
local_domain="foo.local"

# backup /etc/hosts file
if [ ! -f /etc/hosts.orig ]; then
	# backup original hosts file
	sudo cp /etc/hosts /etc/hosts.orig
else
	# get timestamp
	timestamp=$(date "+%Y%m%d%H%M%S")

	# backup /etc/hosts file with a timestamp
	sudo cp /etc/hosts /etc/hosts-$timestamp
fi

# add domain name to /etc/hosts file
sudo sed -i "s/\\(127\\.0\\.0\\.1\\s\\+.*\\)/\\1 $local_domain/" /etc/hosts

