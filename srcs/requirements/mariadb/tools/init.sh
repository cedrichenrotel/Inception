#!/bin/sh
set -e

DB_PASSWORD=$(cat /run/secrets/db_password)
DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)

if [ ! -d "/var/lib/mysql/wordpress" ]; then
    echo "création de la base..."

    mariadbd --user=mysql &

    # boucle qui verifie toute les seconde si Mariadb est pret
    until mariadb-admin ping --silent; do
        sleep 1
    done

    # envois script de 4 instructions a mariadb pour executer en sql
    mariadb -e"
        CREATE DATABASE IF NOT EXISTS wordpress;
        CREATE USER IF NOT EXISTS 'wpuser'@'%' IDENTIFIED BY '$DB_PASSWORD';
        GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'%';
        ALTER USER 'root'@'localhost' IDENTIFIED BY '$DB_ROOT_PASSWORD';
        "

    # arrete mariadb
    mariadb-admin -u root -p"$DB_ROOT_PASSWORD" shutdown

fi

exec mariadbd --user=mysql
