#!/bin/bash

# settings
local_domain="foo.local"

# add domain name to /etc/hosts file
sudo sed -i "s/\\(127\\.0\\.0\\.1\\s\\+.*\\)/\\1 $local_domain/" /etc/hosts

