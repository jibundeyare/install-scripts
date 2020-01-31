# Install scripts

## Description

The scripts in this repo help doing the follwing tasks:

- install and configure the LAMP stack (Apache, MySQL and PHP FPM on Linux) then configure a project directory
- install PHPMyAdmin with an HTTP authentication
- reset PHPMyAdmin HTTP authentication password
- create a new website (project directory, virtual host, PHP FPM pool)
- remove a website (virtual host and PHP FPM pool but not the project directory)
- add a domain to the `/etc/hosts` file (the script backs up the file before modifying it)
- remove a domain from the `/etc/hosts` file (the script backs up the file before modifying it)

The `rmwebsite.sh` takes care of removing the virtual host and the PHP FPM pool but it never touches the projet directory nor the files int it.
Your code is too valuable. There's no `rm -fr` command in these scripts.

These scripts come with no warranty at all.
**Use these at your own risks!**

## Prerequisites

These scripts were thouroughly tested with Debian 9 Stretch.

The install scripts need to be adapted to work with Debian 10 Buster.

## Usage

Before launching a script, open it and edit the `# settings` section.
Choose the variable values with care.

If you stick to the posix characters (`a-zA-Z0-9_-.`) you'll be safe.
Avoid spaces and other specials characters.

