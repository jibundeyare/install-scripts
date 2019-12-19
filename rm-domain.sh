#!/bin/bash

# settings
local_domain="foo.local"

# remove domain name from /etc/hosts file
sudo sed -i "s/ $local_domain//" /etc/hosts

