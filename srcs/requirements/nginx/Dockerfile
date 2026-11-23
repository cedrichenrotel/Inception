FROM debian:bookworm

RUN apt-get update && apt-get upgrade -y && apt-get install openssl nginx -y

RUN openssl req -keyout /etc/ssl/private/nginx.key \
    -out /etc/ssl/certs/nginx.crt \
    -x509 -nodes -days 365 \
    -subj "/CN=cehenrot.42.fr"

COPY conf/default.conf /etc/nginx/conf.d/

CMD ["nginx", "-g", "daemon off;"]
