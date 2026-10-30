# RUNBOOK GestStock

## Démarrer
```bash
cp secrets/*.example secrets/  # ou créer db_password.txt / db_root_password.txt
docker compose up -d --build --wait
open http://localhost:8083/?health
```

## Mettre à jour (rolling)
```bash
docker compose build app && docker compose up -d --no-deps --scale app=2 app
# puis retire l'ancien réplica
```

## Rollback
Retagger l'image précédente / `VERSION=... docker compose up -d`.

## Sauvegarde / restauration
`./scripts/backup.sh` puis `./scripts/restore.sh backups/STAMP`.

## Rapport quotidien
`docker compose --profile ops run --rm rapport` (testable à la demande).  
Cron hôte ou ofelia/supercronic en prod.

## Logs / métriques
Logs JSON-file Docker → Promtail/Loki (rejoindre `geststock_front` depuis la stack TP07).  
cAdvisor pour CPU/mémoire.

## Secrets
Fichiers `secrets/*.txt` **hors git**. Rotation : nouveaux fichiers + recreate db/app.
