FROM debian:bookworm

RUN apt-get update && apt-get upgrade -y && apt install php-cli php-mysql curl -y

RUN mkdir -p /var/www/html && curl -L -o /var/www/html/index.php \
    https://www.adminer.org/latest.php

CMD ["php", "-S", "0.0.0.0:8081", "-t", "/var/www/html"]