# Inception — Plan de route

> Feuille de route pour ne pas se perdre. Cocher `[x]` au fur et à mesure.
> Référence : `SUBJECT.md` (sujet complet). Login : `cehenrot` → domaine `cehenrot.42.fr`.

---

## 📍 État actuel (26/11/2026)

**Où on en est :** 🎉 **toute la stack tourne dans la VM** : WordPress sur `https://cehenrot.42.fr` (TLSv1.3),
site statique sur `:8080`, Adminer sur `:8081`. Makefile et 2 bonus faits.

### 🔜 Reste à faire (dans l'ordre)

1. 🐞 **Bug utilisateurs WordPress** (bloquant, voir Phase 5) → corriger, push, `git pull` dans la VM, `make re`
2. **Tests finaux** (Phase 9)
3. **Documentation** (Phase 10) : README en anglais, `USER_DOC.md`, `DEV_DOC.md`
4. Petits nettoyages : Adminer `latest.php` → version précise, site par défaut nginx (port 80), healthcheck MariaDB
5. Commiter ou annuler la modif de `nginx/conf/default.conf` (juste un espace dans `server_name`)
6. Bonus restants (Redis, FTP, service au choix) + préparer la soutenance

**Adresses (Firefox, DANS la VM, pas sur le PC de 42) :**

| Service | Adresse |
|---|---|
| WordPress | `https://cehenrot.42.fr` (sans `www.`) |
| Admin WordPress | `https://cehenrot.42.fr/wp-admin` |
| Site statique (bonus) | `http://cehenrot.42.fr:8080` |
| Adminer (bonus) | `http://cehenrot.42.fr:8081` → serveur `mariadb`, user `wpuser`, base `wordpress` |

**Workflow :** je code sur le PC → `git push` → dans la VM `git pull` → `make re`.
`srcs/.env` et `secrets/` sont ignorés par git : à recopier à la main sur chaque machine.

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

> 26/11 : VM **réinstallée** (`cedric-virtualbox`), tout a été refait dessus.

- [x] Installer Docker : `docker.io` + **`docker-compose-v2` + `docker-buildx`**
      (sans le plugin compose → erreur `unknown shorthand flag: 'f'`)
- [x] Groupe docker : `sudo usermod -aG docker cehenrot` → **se déconnecter/reconnecter**
      (sinon `permission denied` sur `docker.sock`)
- [x] Installer `make` et `git` (⚠️ `sudo` devant **chaque** commande d'une ligne avec `&&`)
- [x] Cloner le dépôt dans la VM
- [x] Copier `secrets/` et `srcs/.env` du PC vers la VM (`scp -P 4242`)
- [x] Domaine : `echo "127.0.0.1 cehenrot.42.fr" | sudo tee -a /etc/hosts`
- [x] Dossiers `~/data/mariadb` et `~/data/wordpress` → créés par le Makefile
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
- [x] Volume vide au 1er lancement : pas de souci, Docker y copie le contenu de `/var/lib/mysql` de l'image

---

## Phase 5 — WordPress + php-fpm (sans nginx)

- [x] Dockerfile : `php-fpm` + extensions (`php-mysql`…) + `wp-cli`
- [x] Config php-fpm (`conf/www.conf`) : écouter sur le port `9000` (et non sur un socket)
- [x] Script d'init (`tools/setup.sh`) : télécharger WordPress, `wp config create` (boucle `until` = attente MariaDB), `wp core install --url=https://...`
- [x] Créer **2 utilisateurs** : un administrateur (**son nom ne doit PAS contenir « admin »**) + un utilisateur normal
- [x] Attendre que MariaDB soit prête avant l'installation
- [x] Donner les fichiers à `www-data` (`chown -R www-data:www-data /var/www/html`)
- [x] Finir par `exec php-fpm8.2 -F` (au premier plan, PID 1)

---

## Phase 6 — NGINX (seule porte d'entrée)

- [x] Dockerfile : nginx + openssl
- [x] Générer un certificat auto-signé (pour `cehenrot.42.fr`)
- [x] Config (`conf/default.conf`) : `listen 443 ssl;` et `ssl_protocols TLSv1.2 TLSv1.3;` **uniquement**
- [x] Test seul : `curl -k https://localhost` OK, TLS 1.1 refusé (`openssl s_client -tls1_1`)
- [x] Transmettre le PHP à `wordpress:9000` (`location ~ \.php$` + `fastcgi_pass`), `index index.php`
- [x] Monter le volume des fichiers WordPress (pour servir les fichiers statiques)
- [x] `nginx -g 'daemon off;'` (au premier plan)
- [x] Aucun port 80 exposé, **uniquement le 443**

---

## Phase 7 — docker-compose.yml

- [x] 3 services : `mariadb`, `wordpress`, `nginx`, avec `build:` (pas d'images téléchargées)
- [x] `image:` = même nom que le service, **+ `pull_policy: build`** (sinon compose télécharge l'image officielle !)
- [x] `restart: unless-stopped` sur chaque service (testé : `docker exec nginx nginx -s stop` → relancé)
- [x] Un réseau personnalisé (`networks: inception`, driver `bridge`) : **interdit** `network: host`, `links:`, `--link`
- [x] 2 **volumes nommés** (`volume_mariadb`, `volume_wordpress`) dont les données vont dans `~/data/...`
      (`driver: local` + `driver_opts` `type: none`, `o: bind`, `device: ...`). Wordpress partagé avec nginx.
- [ ] ⚠️ `device:` est en dur `/home/henrotel/...` → à l'école mettre `/home/cehenrot/...` (ou `${HOME}/data/...`)
- [x] `env_file: .env` et `secrets:` (mariadb + wordpress : `db_password`, `credentials`)
- [x] `depends_on` : wordpress → mariadb, nginx → wordpress
- [x] Seul nginx publie un port : `443:443`

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
| 23/11 | moi | Volumes nommés dans `~/data` : persistance vérifiée (base et fichiers WP survivent à un `down`) |
| 24/11 | moi | ports/depends_on/restart, setup.sh complet (2 comptes), fastcgi nginx, /etc/hosts → **site WordPress affiché** 🎉 |
