# TP Docker — évaluation niveau

Infrastructure WordPress + MariaDB + Nginx (Compose).

## Prérequis

- Docker et Docker Compose v2
- Ports 8080 (HTTP) libre ; 8081 si profil admin

## Installation

```bash
cp .env.example .env
mkdir -p secrets
openssl rand -base64 24 > secrets/db_root_password.txt
openssl rand -base64 24 > secrets/db_password.txt
chmod 600 secrets/*.txt
chmod +x scripts/*.sh
```

## Déploiement

```bash
docker compose up -d
docker compose ps
```

Application : http://localhost:8080

Profil admin (phpMyAdmin) :

```bash
docker compose --profile admin up -d
```

http://localhost:8081 — connexion avec l'utilisateur BDD défini dans `.env`.

## Arrêt

```bash
docker compose down
```

Conserver les données : ne pas utiliser `-v`.

## Vérifications

```bash
curl -I http://localhost:8080
```

Variables d'environnement WordPress (depuis le conteneur) :

```bash
docker compose exec wordpress env | grep WORDPRESS_DB
```

MariaDB non exposée sur l'hôte :

```bash
nc -zv localhost 3306
```

## Sauvegarde / restauration

```bash
./scripts/backup.sh
./scripts/restore.sh backups/YYYYMMDD-HHMMSS
```

## Persistance

```bash
docker compose up -d
docker compose rm -sf wordpress mariadb nginx
docker compose up -d
```

Les volumes nommés conservent site et base.

## CI locale

```bash
docker compose config
```
