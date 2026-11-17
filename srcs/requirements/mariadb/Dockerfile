FROM debian:bookworm

RUN apt-get update && \
    apt-get install --no-install-recommends -y mariadb-server && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

EXPOSE 3306

HEALTHCHECK --start-period=5m \
  CMD mariadb -e 'SELECT @@datadir;' || exit 1

CMD ["mariadbd", "--user=mysql"]