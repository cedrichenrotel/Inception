FROM debian:bookworm

RUN apt update && apt install php-fpm php-mysql curl -y

RUN curl -o /usr/local/bin/wp \
    https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x /usr/local/bin/wp 

COPY conf/www.conf /etc/php/8.2/fpm/pool.d/
COPY tools/setup.sh /usr/local/bin/setup.sh

RUN chmod +x /usr/local/bin/setup.sh

CMD ["setup.sh"]
