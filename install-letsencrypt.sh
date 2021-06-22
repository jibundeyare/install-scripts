#!/bin/bash

function usage {
	this=$(basename $0)
	cat <<-EOT
	Usage: $this [EMAIL] [DOMAIN]

	This script installs certbot, an automated SSL certificate installation and renewal tool.
	The script transmits the email address to certbot.

	WARNING You need a domain name to be able to activate the HTTPS protocol.

	EMAIL should be a personal email for receiving important account notifications.
	DOMAIN is the domain name you will be using in your web browser to access a particular project.
	  In fact the domain name is not used in the script but adding here ensures that you do have one.

	Example: $this johndoe@mail.com example.com

	This command will :

	- install snap
	- install certbot
	- set "johndoe@mail.com" as the email address for certbot
	- check that a cetrbot timer exists
	- start certbot in interactive mode
	EOT
}

if [ $# -lt 2 ]; then
	usage
	exit 1
else
	# settings
	email="$1"
	domain="$2"

	cat <<-EOT
	EMAIL: $email
	DOMAIN: $domain

	EOT

	read -p "Press [y/Y] to confirm: " answer
	echo ""

	if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
		echo "canceled"
		exit
	fi
fi

# check that the script is not run as root
current_id="$(id -nu)"

if [ "$current_id" == "root" ]; then
	echo "error: this script should not be run as root"
	exit 1
fi

# check that user is a sudoer
sudo_id=$(sudo id -nu)

if [ "$sudo_id" != "root" ]; then
	echo "error: you must be a sudoer to use this script"
	exit 1
fi

# [How To Secure Apache with Let's Encrypt on Debian 9 | DigitalOcean](https://www.digitalocean.com/community/tutorials/how-to-secure-apache-with-let-s-encrypt-on-debian-9)
# [Secure Apache with Let's Encrypt on Debian 10 | Linuxize](https://linuxize.com/post/secure-apache-with-let-s-encrypt-on-debian-10/)
# [LetsEncrypt - Debian Wiki](https://wiki.debian.org/LetsEncrypt)
# [Certbot - Debianbuster Apache](https://certbot.eff.org/lets-encrypt/debianbuster-apache)
# [Instructions on how to setup a Letsencrypt SSL certificate on a WordPress site](https://gist.github.com/harryfinn/e36e41cdbfba5a6e1d69d6498a4fc5ee)

sudo apt update
sudo apt install -y snapd
sudo snap install core
sudo snap refresh core
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot

# Enabled Apache socache_shmcb module
# Enabled Apache ssl module
# Created an SSL vhost at /etc/apache2/sites-available/bar-le-ssl.conf
# Deploying Certificate to VirtualHost /etc/apache2/sites-available/bar-le-ssl.conf
# Redirecting vhost in /etc/apache2/sites-enabled/bar.conf to ssl vhost in /etc/apache2/sites-available/bar-le-ssl.conf

# check that there is a certbot cronjob
sudo systemctl list-timers | grep certbot

if [ "$?" != "0" ]; then
	echo "error: certbot timer not found"
	exit 1
fi

# get certificate and install it for all domains
sudo certbot --email $email --agree-tos --no-eff-email --keep-until-expiring

# Saving debug log to /var/log/letsencrypt/letsencrypt.log
# Plugins selected: Authenticator apache, Installer apache
#
# Which names would you like to activate HTTPS for?
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 1: bar.jibundeyare.fr
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Select the appropriate numbers separated by commas and/or spaces, or leave input
# blank to select all options shown (Enter 'c' to cancel):
# Cert not yet due for renewal
# Keeping the existing certificate
# Created an SSL vhost at /etc/apache2/sites-available/bar-le-ssl.conf
# Enabled Apache socache_shmcb module
# Enabled Apache ssl module
# Deploying Certificate to VirtualHost /etc/apache2/sites-available/bar-le-ssl.conf
# Enabling available site: /etc/apache2/sites-available/bar-le-ssl.conf
# Redirecting vhost in /etc/apache2/sites-enabled/bar.conf to ssl vhost in /etc/apache2/sites-available/bar-le-ssl.conf
#
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Congratulations! You have successfully enabled https://bar.jibundeyare.fr
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#
# IMPORTANT NOTES:
#  - If you like Certbot, please consider supporting our work by:
#
#    Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
#    Donating to EFF:                    https://eff.org/donate-le

# @info stop here
exit

# # get certificate only for main domain only
# sudo certbot certonly --email $email --agree-tos --no-eff-email --keep-until-expiring --webroot --webroot-path projects/www/ -d jibundeyare.fr
#
# # Saving debug log to /var/log/letsencrypt/letsencrypt.log
# # Plugins selected: Authenticator webroot, Installer None
# # Requesting a certificate for jibundeyare.fr
# # Performing the following challenges:
# # http-01 challenge for jibundeyare.fr
# # Using the webroot path /home/daishi/projects/www for all unmatched domains.
# # Waiting for verification...
# # Cleaning up challenges
# #
# # IMPORTANT NOTES:
# #  - Congratulations! Your certificate and chain have been saved at:
# #    /etc/letsencrypt/live/jibundeyare.fr/fullchain.pem
# #    Your key file has been saved at:
# #    /etc/letsencrypt/live/jibundeyare.fr/privkey.pem
# #    Your certificate will expire on 2021-04-20. To obtain a new or
# #    tweaked version of this certificate in the future, simply run
# #    certbot again. To non-interactively renew *all* of your
# #    certificates, run "certbot renew"
# #  - If you like Certbot, please consider supporting our work by:
# #
# #    Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
# #    Donating to EFF:                    https://eff.org/donate-le
#
# # get certificate and install it for main domain only
# sudo certbot --email $email --agree-tos --no-eff-email --keep-until-expiring --webroot-path projects/www -d jibundeyare.fr
#
# # Saving debug log to /var/log/letsencrypt/letsencrypt.log
# # Plugins selected: Authenticator apache, Installer apache
# # Cert not yet due for renewal
# # Keeping the existing certificate
# # Created an SSL vhost at /etc/apache2/sites-available/000-default-le-ssl.conf
# # Deploying Certificate to VirtualHost /etc/apache2/sites-available/000-default-le-ssl.conf
# # Enabling available site: /etc/apache2/sites-available/000-default-le-ssl.conf
# # Redirecting vhost in /etc/apache2/sites-enabled/000-default.conf to ssl vhost in /etc/apache2/sites-available/000-default-le-ssl.conf
# #
# # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# # Congratulations! You have successfully enabled https://jibundeyare.fr
# # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# #
# # IMPORTANT NOTES:
# #  - If you like Certbot, please consider supporting our work by:
# #
# #    Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
# #    Donating to EFF:                    https://eff.org/donate-le
#
# # get certificate only for subdomain only
# sudo certbot certonly --email $email --agree-tos --no-eff-email --keep-until-expiring --apache -d bar.jibundeyare.fr
#
# # Saving debug log to /var/log/letsencrypt/letsencrypt.log
# # Plugins selected: Authenticator apache, Installer apache
# # Requesting a certificate for bar.jibundeyare.fr
# #
# # IMPORTANT NOTES:
# #  - Congratulations! Your certificate and chain have been saved at:
# #    /etc/letsencrypt/live/bar.jibundeyare.fr/fullchain.pem
# #    Your key file has been saved at:
# #    /etc/letsencrypt/live/bar.jibundeyare.fr/privkey.pem
# #    Your certificate will expire on 2021-04-20. To obtain a new or
# #    tweaked version of this certificate in the future, simply run
# #    certbot again. To non-interactively renew *all* of your
# #    certificates, run "certbot renew"
# #  - If you like Certbot, please consider supporting our work by:
# #
# #    Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
# #    Donating to EFF:                    https://eff.org/donate-le
#
# # get certificate and install it for subdomain only
# sudo certbot --email $email --agree-tos --no-eff-email --keep-until-expiring -d bar.jibundeyare.fr
#
# # Saving debug log to /var/log/letsencrypt/letsencrypt.log
# # Plugins selected: Authenticator apache, Installer apache
# # Cert not yet due for renewal
# # Keeping the existing certificate
# # Created an SSL vhost at /etc/apache2/sites-available/bar-le-ssl.conf
# # Deploying Certificate to VirtualHost /etc/apache2/sites-available/bar-le-ssl.conf
# # Enabling available site: /etc/apache2/sites-available/bar-le-ssl.conf
# # Redirecting vhost in /etc/apache2/sites-enabled/bar.conf to ssl vhost in /etc/apache2/sites-available/bar-le-ssl.conf
# #
# # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# # Congratulations! You have successfully enabled https://bar.jibundeyare.fr
# # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# #
# # IMPORTANT NOTES:
# #  - If you like Certbot, please consider supporting our work by:
# #
# #    Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
# #    Donating to EFF:                    https://eff.org/donate-le

