#!/bin/bash

DB_PASSWORD=$(cat /run/secrets/db_password)
. /run/secrets/credentials

mkdir -p /var/www/html
cd /var/www/html

if [ ! -f "wp-config.php" ]; then
    wp core download --allow-root

    until wp config create --allow-root --dbname=$MYSQL_DATABASE \
        --dbuser=$MYSQL_USER --dbpass="$DB_PASSWORD" --dbhost=mariadb:3306; do
        sleep 2
    done
    wp core install --url=https://$DOMAIN_NAME --title="$WP_TITLE" \
       --admin_user=$WP_ADMIN_NAME --admin_password="$WP_ADMIN_PASSWORD" \
       --admin_email=$WP_ADMIN_EMAIL --skip-email --allow-root

    wp user create $WP_USER_NAME $WP_USER_EMAIL --user_pass="$WP_USER_PASSWORD" \
       --role=author --allow-root
fi

chown -R www-data:www-data /var/www/html

exec php-fpm8.2 -F