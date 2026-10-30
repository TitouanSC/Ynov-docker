# GestStock Docker (TP10 fil rouge)

Stack PHP **8.3-apache** + MariaDB 11.4 + Traefik (file provider) + Mailpit + rapport on-demand.

## Choix techniques

| Sujet | Choix | Pourquoi |
|-------|--------|----------|
| Runtime web | `php:8.3-apache` | Un seul conteneur, migration legacy rapide ; nginx+fpm serait mieux pour isoler mais +ops |
| Cron rapport | `docker compose --profile ops run rapport` (+ cron hôte) | Observabilité claire (conteneur éphémère), pas de daemon cron dans l'image app |
| Uploads prod | volume nommé local | Simple ; NFS/S3 possible ensuite via sidecar |

## Démarrage

```bash
echo 'gest-pass' > secrets/db_password.txt
echo 'gest-root' > secrets/db_root_password.txt
docker compose up -d --build --wait
curl -sf 'http://127.0.0.1:8083/?health'
./ci-local.sh
```

## Fichiers clés

- `compose.yml` + `compose.override.yml` (dev) + `compose.prod.yml` + `compose.hardened.yml`
- `scripts/{backup,restore,migrate-from-legacy,audit}.sh`
- `RUNBOOK.md` — ops quotidiennes
- `.github/workflows/geststock.yml` — lint PHP + smoke compose

## Observabilité

Rejoindre le réseau `geststock_front` depuis la stack Promtail/Loki/cAdvisor du TP07 (labels `com.docker.compose.project=geststock`).
