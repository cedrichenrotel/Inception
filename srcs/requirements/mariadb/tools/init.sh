#!/bin/sh
set -e

DB_PASSWORD=$(cat /run/secrets/db_password)
DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)


if [ ! -d "/var/lib/mysql/$MYSQL_DATABASE" ]; then
    echo "création de la base..."

    mariadbd --user=mysql &

    until mariadb-admin ping --silent; do
        sleep 1
    done

    mariadb -e"
        CREATE DATABASE IF NOT EXISTS $MYSQL_DATABASE;
        CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$DB_PASSWORD';
        GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'%';
        ALTER USER 'root'@'localhost' IDENTIFIED BY '$DB_ROOT_PASSWORD';
        "

    mariadb-admin -u root -p"$DB_ROOT_PASSWORD" shutdown

fi

exec mariadbd --user=mysql
