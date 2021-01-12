#!/bin/bash

conf_file="mariadb-backups-conf.sh"

if [ ! -f "$conf_file" ]; then
	echo "error: missing conf file '$conf_file'"
	echo ""
	echo "did you forget to create one ?"
	echo "use '$conf_file.dist' as a base file"
	exit 1
fi

source $conf_file

mkdir -p $backups_directory

timestamp=$(date +%Y%m%d%H%M%S)
echo "timestamp: $timestamp"

databases=$(mariadb -h $server -u $login --password=$password -e "SHOW DATABASES;" | cat)

sql_file=""
archive_file=""

for database in $databases; do
	if [ "$database" != "Database" ] && [ "$database" != "information_schema" ] && [ "$database" != "mysql" ] && [ "$database" != "performance_schema" ]; then
		echo "database: $database"

		sql_file="db.sql"
		archive_file="$database-$timestamp.sql.gz"
		mysqldump -h $server -u $login --password=$password --order-by-primary --tz-utc $database > $sql_file
		mkdir -p $backups_directory/$database
		gzip -c $sql_file > $backups_directory/$database/$archive_file
		rm $sql_file
	fi
done

