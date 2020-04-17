# Install scripts

Install and helper scripts for Debian 10 Buster.

## Description

There are two categories of scripts in this repo:

- install scripts for installing useful services or packages
- helper scripts for configuring or removing web applications

The install scripts do the follwing tasks:

- install and configure a firewall (currently unavailable)
- install nvm
- install python pip
- install and configure the LAMP stack (Apache, MySQL and PHP FPM on Linux) then configure a project directory
- install PHPMyAdmin from debian package, configures an HTTP authentication (currently unavailable)
- install PHPMyAdmin from source, configures an HTTP authentication
- reset PHPMyAdmin HTTP authentication password

The helper scripts do the follwing tasks:

- create a new website (project directory, virtual host, PHP FPM pool)
- remove a website (virtual host and PHP FPM pool but not the project directory)
- add a domain to the `/etc/hosts` file (the script backs up the file before modifying it)
- remove a domain from the `/etc/hosts` file (the script backs up the file before modifying it)
- add a new database and a dedicated user
- drop a database and its dedicated user

Note: the `rmwebsite.sh` takes care of removing the virtual host and the PHP FPM pool but it never touches the projet directory nor the files int it.
Your code is too valuable. There's no `rm -fr` command in these scripts.

Warning: the `rmdb.sh` script does drop the specified database without any possibility of recovery, so use it with care.

These scripts come with no warranty at all.
**Use these at your own risks!**

## Prerequisites

These scripts are meant to work with Debian 10 Buster but have not been thouroughly tested yet.

## Usage

Just run any script without any parameter and it will display a help screen.
Choose the parameters value with care.

If you stick to posix characters (`a-zA-Z0-9_-.`) you'll be safe.
Avoid spaces and other specials characters.

