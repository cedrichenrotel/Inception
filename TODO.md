# Inception — Plan de route

> Feuille de route pour ne pas se perdre. Cocher `[x]` au fur et à mesure.
> Référence : `SUBJECT.md` (sujet complet). Login : `cehenrot` → domaine `cehenrot.42.fr`.

---

## 📍 État actuel (23/11/2026)

**Où on en est :** les 3 conteneurs démarrent ensemble avec `docker compose -f srcs/docker-compose.yml up --build`
(mariadb `healthy`). Il manque : volumes, port 443, `depends_on`, `restart`, la fin de `setup.sh`
(installation WordPress) et le lien nginx → php-fpm. 👉 **Prochaine étape : les volumes (Phase 7).**

- Travail aussi sur l'**ordi perso** (Ubuntu 25.10, sans VM) : `docker.io` + `docker-compose-v2` installés.
  `srcs/.env` et `secrets/` y ont été recréés (ignorés par git, donc à recréer sur chaque machine).

### Historique (16/11/2026)

- [x] VM VirtualBox `inception` créée (Ubuntu 26.04, 2 Go RAM, 1 CPU)
- [x] SSH vers la VM fonctionnel : `ssh -p 4242 cehenrot@localhost`
- [x] Dépôt Git créé (`github.com/cedrichenrotel/Inception`) : 2 commits, presque vide
- [x] **Inventaire de ce que le collègue a fait DANS la VM** (voir Phase 0)
- [x] Accès SSH par clé depuis le PC hôte (Claude peut lancer des commandes dans la VM)

### Résultat de l'inventaire (16/11)

**Déjà OK dans la VM** (`cehenrot-virtualbox`, Ubuntu 26.04.1, 25 Go disque, 2 Go RAM) :
- Docker 29.9.3 + Docker Compose v5.7.1 installés, `cehenrot` est dans le groupe `docker`
- `make` et `git` installés
- Dépôt cloné dans `~/Inception` (remote `git@github.com:cedrichenrotel/Inception.git`)

**Pas encore fait :**
- `~/data` n'existe pas
- `cehenrot.42.fr` absent de `/etc/hosts`

**Brouillon du collègue dans `~/Inception`** (non commité : Makefile, Dockerfile, docker-compose.yml, env.mk, .env vide) :
- ⚠️ C'est un **modèle copié d'un autre projet** (service `backend`, base Postgres, `TOKEN_SECRET`…) : rien à voir avec Inception
- Viole le sujet : `CMD ["bash"]`, pas de `networks:`, mot de passe en clair dans `DATABASE_URL`, fichiers à la racine au lieu de `srcs/`
- Le Makefile utilise l'image `alpine` sans tag (= `latest`, interdit) et `docker system prune -af` (efface **tout** Docker)
- Bonne idée à garder : Debian `bookworm` (12) est bien l'avant-dernière stable (la stable actuelle est Debian 13 `trixie`)
- Restes de tests : conteneur `mon-conteneur` (arrêté) + image `test:latest` → à supprimer
- 👉 Décision : **repartir de zéro** en suivant ce plan, sans réutiliser ce brouillon

---

## Phase 0 — Faire l'inventaire de l'existant

À lancer dans la VM (connectée en SSH) :

```bash
hostname ; ls -la ~ ; ls ~/data
docker --version ; docker compose version
docker ps -a ; docker images ; docker volume ls ; docker network ls
find ~ \( -name docker-compose.yml -o -name Makefile -o -name Dockerfile \) 2>/dev/null
```

- [x] Noter ce qui existe déjà (Docker installé ? fichiers ? conteneurs ?)
- [ ] Demander au collègue ce qu'il a fait / où il s'est arrêté
- [x] Mettre à jour la section « État actuel » ci-dessus

---

## Phase 1 — Préparer la VM

- [x] Installer Docker Engine + plugin `docker compose` (dépôt officiel Docker)
- [x] Ajouter l'utilisateur au groupe docker : `sudo usermod -aG docker cehenrot` (puis se reconnecter)
- [ ] Vérifier : `docker run --rm hello-world` (test uniquement, ne fait pas partie du projet)
- [x] Installer `make` et `git`
- [x] Cloner le dépôt dans la VM
- [ ] Nettoyer les restes de tests : `docker rm mon-conteneur && docker rmi test:latest`
- [ ] Domaine : ajouter `127.0.0.1 cehenrot.42.fr` dans `/etc/hosts`
- [ ] Créer les dossiers des volumes : `/home/cehenrot/data/mariadb` et `/home/cehenrot/data/wordpress`
- [ ] (Optionnel) Redirection de port VirtualBox 443 → 443 pour tester depuis le PC
- [ ] 💡 Faire un **snapshot** de la VM une fois prête (il n'y en a aucun pour l'instant)

**À comprendre :** VM vs conteneur, ce qu'est une image, un conteneur, un volume, un réseau Docker.

---

## Phase 2 — Créer l'arborescence

```
.
├── Makefile
├── secrets/                  ← ignoré par git !
│   ├── credentials.txt
│   ├── db_password.txt
│   └── db_root_password.txt
└── srcs/
    ├── docker-compose.yml
    ├── .env                  ← ignoré par git !
    └── requirements/
        ├── mariadb/   (Dockerfile, .dockerignore, conf/, tools/)
        ├── nginx/     (Dockerfile, .dockerignore, conf/, tools/)
        └── wordpress/ (Dockerfile, .dockerignore, conf/, tools/)
```

- [x] Créer les dossiers et fichiers vides
- [x] Ajouter `secrets/` et `srcs/.env` au `.gitignore` **avant le premier commit** ⚠️
- [x] Choisir l'image de base : **avant-dernière version stable** de Debian ou d'Alpine
      → choisi : **Debian 12 `bookworm`** (la stable actuelle est Debian 13 `trixie`)
- [x] Jamais de tag `latest`, toujours une version précise (`debian:bookworm`)

---

## Phase 3 — Variables d'environnement et secrets

- [x] `srcs/.env` : `DOMAIN_NAME`, `MYSQL_DATABASE`, `MYSQL_USER`, noms des utilisateurs WP, emails…
- [x] `secrets/*.txt` : mots de passe (BDD, root BDD, utilisateurs WordPress)
      → créés **dans la VM uniquement** (`chmod 600`). `credentials.txt` = `WP_ADMIN_PASSWORD=...` / `WP_USER_PASSWORD=...`
- [ ] Mettre 2 mots de passe WordPress **différents** dans `credentials.txt`
- [x] Déclarer les secrets dans `docker-compose.yml` (`secrets:`), ils seront lus dans `/run/secrets/...`
      → fait pour mariadb (`db_password`, `db_root_password`). `credentials` déclaré mais pas encore utilisé (WordPress).
- [ ] Vérifier : **aucun mot de passe dans les Dockerfiles ni dans git**

**À comprendre :** différence entre secrets et variables d'environnement.

---

## Phase 4 — MariaDB (à faire en premier, les autres en dépendent)

- [x] Dockerfile : base Debian/Alpine + installation de `mariadb-server`
- [x] Config : écouter sur `0.0.0.0:3306` (pas seulement localhost)
- [x] Script d'init (`tools/init.sh`) : créer la base, l'utilisateur, le mot de passe root (lus depuis les secrets)
- [x] Le script finit par `exec mariadbd --user=mysql` → le serveur devient le **PID 1** (pas de `tail -f`, pas de `sleep`)
- [x] Test : `docker exec -it mariadb mariadb -u <user> -p` puis `SHOW DATABASES;`
- [x] `HEALTHCHECK` avec `mariadb-admin ping --silent` (le « Access denied root » dans les logs est normal)
- [ ] ⚠️ À vérifier avec les volumes : dossier `/var/lib/mysql` vide au 1er lancement → il faudra peut-être `mariadb-install-db`

---

## Phase 5 — WordPress + php-fpm (sans nginx)

- [x] Dockerfile : `php-fpm` + extensions (`php-mysql`…) + `wp-cli`
- [x] Config php-fpm (`conf/www.conf`) : écouter sur le port `9000` (et non sur un socket)
- [ ] Script d'init (`tools/setup.sh`) : ~~télécharger WordPress~~ ✅, `wp config create`, `wp core install`
- [ ] Créer **2 utilisateurs** : un administrateur (**son nom ne doit PAS contenir « admin »**) + un utilisateur normal
- [ ] Attendre que MariaDB soit prête avant l'installation
- [ ] Donner les fichiers à `www-data` (`chown -R www-data:www-data /var/www/html`)
- [x] Finir par `exec php-fpm8.2 -F` (au premier plan, PID 1)

---

## Phase 6 — NGINX (seule porte d'entrée)

- [x] Dockerfile : nginx + openssl
- [x] Générer un certificat auto-signé (pour `cehenrot.42.fr`)
- [x] Config (`conf/default.conf`) : `listen 443 ssl;` et `ssl_protocols TLSv1.2 TLSv1.3;` **uniquement**
- [x] Test seul : `curl -k https://localhost` OK, TLS 1.1 refusé (`openssl s_client -tls1_1`)
- [ ] Transmettre le PHP à `wordpress:9000` (`location ~ \.php$` + `fastcgi_pass`), `index index.php`
- [ ] Monter le volume des fichiers WordPress (pour servir les fichiers statiques)
- [x] `nginx -g 'daemon off;'` (au premier plan)
- [ ] Aucun port 80 exposé, **uniquement le 443**

---

## Phase 7 — docker-compose.yml

- [x] 3 services : `mariadb`, `wordpress`, `nginx`, avec `build:` (pas d'images téléchargées)
- [x] `image:` = même nom que le service, **+ `pull_policy: build`** (sinon compose télécharge l'image officielle !)
- [ ] `restart: always` (ou `unless-stopped`) sur chaque service
- [x] Un réseau personnalisé (`networks: inception`, driver `bridge`) : **interdit** `network: host`, `links:`, `--link`
- [ ] 2 **volumes nommés** (pas de bind mounts) dont les données vont dans `/home/cehenrot/data/...` :
  ```yaml
  volumes:
    mariadb:
      driver: local
      driver_opts: { type: none, o: bind, device: /home/cehenrot/data/mariadb }
  ```
- [x] `env_file: .env` et `secrets:` (mariadb) — [ ] à ajouter aussi pour wordpress
- [ ] `depends_on` : wordpress → mariadb, nginx → wordpress
- [ ] Seul nginx publie un port : `443:443`

---

## Phase 8 — Makefile

- [ ] `all` / `up` : crée les dossiers data puis `docker compose -f srcs/docker-compose.yml up -d --build`
- [ ] `down` : arrête les conteneurs
- [ ] `clean` : down + supprime les images
- [ ] `fclean` : clean + supprime les volumes et `/home/cehenrot/data`
- [ ] `re` : fclean + all

---

## Phase 9 — Tests finaux

- [ ] `make` depuis zéro fonctionne
- [ ] `https://cehenrot.42.fr` affiche WordPress (avertissement de certificat normal)
- [ ] `http://cehenrot.42.fr` (port 80) **ne répond pas**
- [ ] Vérifier TLS : `openssl s_client -connect cehenrot.42.fr:443 -tls1_1` doit **échouer**
- [ ] Connexion à `/wp-admin` avec l'admin, ajout d'un commentaire avec l'autre utilisateur
- [ ] Persistance : `make down` puis `make` → les données sont toujours là
- [ ] Crash : `docker kill <conteneur>` → il redémarre tout seul
- [ ] `docker compose ps` : tout est « Up »
- [ ] `git status` : **aucun secret** n'apparaît

---

## Phase 10 — Documentation (obligatoire, à la racine)

- [ ] `README.md` **en anglais**
  - [ ] 1re ligne en italique : `*This project has been created as part of the 42 curriculum by cehenrot.*`
  - [ ] Sections : Description, Instructions, Resources (+ comment l'IA a été utilisée)
  - [ ] Project description + comparaisons : VM vs Docker, secrets vs variables d'env, réseau Docker vs host, volumes vs bind mounts
- [ ] `USER_DOC.md` : services fournis, démarrer/arrêter, accéder au site et à l'admin, identifiants, vérifier que tout tourne
- [ ] `DEV_DOC.md` : installer depuis zéro, build/lancement, commandes utiles, où sont stockées les données

---

## Phase 11 — Bonus (seulement si le mandatory est parfait)

- [ ] Redis (cache WordPress)
- [ ] Serveur FTP (sur le volume WordPress)
- [ ] Site statique (pas en PHP)
- [ ] Adminer
- [ ] Service au choix (à justifier)

---

## 🎓 Préparer la soutenance

Je dois savoir expliquer **chaque ligne** et être capable de faire une petite modification en direct.

- [ ] Qu'est-ce que le PID 1, et pourquoi pas de `tail -f` ?
- [ ] Comment les conteneurs communiquent (réseau Docker, noms de service = noms d'hôte)
- [ ] Le chemin d'une requête : navigateur → nginx:443 → wordpress:9000 → mariadb:3306
- [ ] Pourquoi TLS 1.2/1.3 seulement ?
- [ ] Où sont les données, et pourquoi elles survivent à un `down`

---

## 📝 Journal

| Date | Qui | Ce qui a été fait |
|------|-----|-------------------|
| 13/11 | collègue | Initial commit (README, SUBJECT, CLAUDE.md) |
| 16/11 | collègue | `.gitignore` |
| 16/11 | moi | Reprise du projet, VM relancée, SSH OK, création de ce plan |
| 16/11 | moi | Clé SSH configurée, inventaire de la VM (Docker OK, brouillon du collègue inutilisable) |
| 16/11 | moi | Brouillon du collègue supprimé, arborescence Phase 2 créée, secrets ignorés par git |
| 16/11 | moi | Phase 3 : `.env` et secrets créés dans la VM |
| 19/11 | moi | nginx (TLS, certificat, conf, CMD), WordPress (php-fpm 9000, wp-cli, setup.sh), MariaDB (init.sh) |
| 20/11 | moi | MariaDB testée seule (healthcheck corrigé), début docker-compose (services + réseau) |
| 23/11 | moi | Compose : secrets, `.env`, `image` + `pull_policy: build` → les 3 conteneurs démarrent ensemble |
