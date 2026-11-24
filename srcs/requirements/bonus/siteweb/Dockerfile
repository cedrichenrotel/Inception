FROM debian:bookworm

RUN apt-get update && apt-get upgrade -y && apt-get install nginx -y

COPY conf/default.conf /etc/nginx/conf.d/
COPY tools/ /var/www/siteweb/

CMD ["nginx", "-g", "daemon off;"]