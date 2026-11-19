FROM debian:bookworm

RUN apt update && apt install openssl nginx -y && \
    openssl req -keyout /etc/ssl/private/nginx.key \
    -out /etc/ssl/certs/nginx.crt \
    -x509 -nodes \
    -subj "/CN=cehenrot.42.fr"

COPY conf/nginx.conf /etc/nginx/conf.d/

CMD ["nginx", "-g", "daemon off;"]
