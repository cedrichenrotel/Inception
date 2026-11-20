#!/bin/bash

mkdir -p /var/www/html
cd /var/www/html

if [ ! -f "wp-config.php" ]; then
    wp core download --allow-root
fi

exec php-fpm8.2 -F