*This project has been created as part of the 42 curriculum by cehenrot.*

# Inception

## Description

Inception is a system administration project. The goal is to build a small web
infrastructure with **Docker** and **Docker Compose**, inside a virtual machine.

Each service runs in its own container, built from my own Dockerfile
(base image: `debian:bookworm`, no ready-made images from Docker Hub):

- **NGINX**: the only entry point, on port 443, with TLSv1.2 / TLSv1.3 only.
- **WordPress + php-fpm**: the website (installed and configured with `wp-cli`).
- **MariaDB**: the database used by WordPress.

Bonus services:

- **Static website**: a simple HTML page served by NGINX (port 8080).
- **Adminer**: a web interface to manage the MariaDB database (port 8081).

The containers talk to each other through a private Docker network called
`inception`. The database and the WordPress files are stored in two volumes,
saved on the host in `~/data/mariadb` and `~/data/wordpress`, so data is kept
after a restart.

### Use of Docker and project sources

```
.
├── Makefile                 # builds and starts everything
├── secrets/                 # passwords (not in git)
└── srcs/
    ├── .env                 # non-secret settings (not in git)
    ├── docker-compose.yml   # describes services, network, volumes, secrets
    └── requirements/
        ├── nginx/           # Dockerfile + conf (TLS, FastCGI to wordpress:9000)
        ├── wordpress/       # Dockerfile + php-fpm conf + setup.sh
        ├── mariadb/         # Dockerfile + server conf + init.sh
        └── bonus/           # siteweb, adminer
```

Main design choices:

- One Dockerfile per service, one process per container (run in the foreground,
  no `tail -f`, no infinite loop).
- Containers restart automatically (`restart: unless-stopped`).
- Passwords are given with **Docker secrets**; other settings with a `.env` file.
- The setup scripts (`init.sh`, `setup.sh`) only configure the service the first
  time; after that, data already present in the volume is reused.

### Virtual Machines vs Docker

A virtual machine emulates a full computer with its own kernel and operating
system: it is very isolated but heavy and slow to start. A Docker container
shares the kernel of the host and only isolates the processes: it is light,
starts in seconds, and is easy to rebuild. In this project, the VM gives a clean
environment, and Docker separates the services inside it.

### Secrets vs Environment Variables

Environment variables are easy to use, but they can be seen with
`docker inspect` or in the process environment. Docker secrets are files mounted
only inside the containers that need them (in `/run/secrets/`), and they are
not stored in the image. That is why passwords are in `secrets/`, and simple
settings (domain name, user names, database name) are in `srcs/.env`.

### Docker Network vs Host Network

With `network: host`, a container uses the network of the host directly: no
isolation, and all its ports are open. With a Docker bridge network, containers
are isolated and can reach each other by name (`mariadb`, `wordpress`) thanks
to Docker's internal DNS. Only the ports I choose (443, and 8080/8081 for the
bonus) are published to the host. The subject forbids `host` and `links`.

### Docker Volumes vs Bind Mounts

A bind mount links any folder of the host directly into a container; it depends
on the host path and Docker does not manage it. A named volume is managed by
Docker (`docker volume ls`, `docker volume rm`). The subject requires named
volumes stored in `/home/<login>/data`, so I use named volumes with the `local`
driver and `driver_opts` pointing to `~/data/mariadb` and `~/data/wordpress`.

## Instructions

### Requirements

- A Linux virtual machine with Docker and Docker Compose installed.
- `make` and `sudo` rights.
- Add the domain to `/etc/hosts`:

  ```
  127.0.0.1   cehenrot.42.fr
  ```

### Configuration

These files are not in the git repository and must be created by hand:

- `srcs/.env` with: `DOMAIN_NAME`, `MYSQL_DATABASE`, `MYSQL_USER`, `WP_TITLE`,
  `WP_ADMIN_USER`, `WP_ADMIN_EMAIL`, `WP_USER`, `WP_USER_EMAIL`.
- `secrets/db_password.txt`: password of the database user.
- `secrets/db_root_password.txt`: password of the MariaDB root user.
- `secrets/credentials.txt`: passwords of the WordPress users.

### Commands

| Command       | Effect                                                       |
|---------------|--------------------------------------------------------------|
| `make`        | create `~/data` folders, build images and start containers  |
| `make down`   | stop and remove the containers                               |
| `make clean`  | `down` + remove the images                                   |
| `make fclean` | `clean` + remove the volumes and the `~/data` folder         |
| `make re`     | `fclean` then `all`                                          |

### Access

- WordPress: `https://cehenrot.42.fr`
- WordPress admin: `https://cehenrot.42.fr/wp-admin`
- Static website (bonus): `http://cehenrot.42.fr:8080`
- Adminer (bonus): `http://cehenrot.42.fr:8081` (server: `mariadb`)

The TLS certificate is self-signed, so the browser shows a warning the first time.

More details: see `USER_DOC.md` (users) and `DEV_DOC.md` (developers).

## Resources

- Docker documentation: https://docs.docker.com/
- Docker Compose file reference: https://docs.docker.com/compose/compose-file/
- Docker secrets in Compose: https://docs.docker.com/compose/how-tos/use-secrets/
- NGINX documentation: https://nginx.org/en/docs/
- MariaDB documentation: https://mariadb.com/kb/en/documentation/
- WP-CLI documentation: https://developer.wordpress.org/cli/commands/
- PHP-FPM configuration: https://www.php.net/manual/en/install.fpm.configuration.php

### Use of AI

I used Claude (Anthropic) as a **mentor**, not as a code generator:

- to explain concepts step by step (containers, PID 1, volumes, secrets,
  networks, TLS, FastCGI);
- to help me understand error messages and debug (for example the NGINX
  resolver to follow the IP of the WordPress container);
- to translate this documentation into English (I wrote it in French).

I wrote the Dockerfiles, configuration files and scripts myself, and I checked
and tested every part.
