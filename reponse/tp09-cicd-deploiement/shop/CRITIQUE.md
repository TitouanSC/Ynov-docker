# Critique du `starter/docker-compose.yml`

| # | Problème | Impact |
|---|----------|--------|
| 1 | Champ `version: '3'` obsolète | Ignoré / warning ; n'apporte rien en Compose V2 |
| 2 | `links:` (db, redis) | API legacy, remplacée par le DNS des réseaux user-defined |
| 3 | Images non épinglées (`postgres`, `redis`) | Builds non reproductibles, surprises au `pull` |
| 4 | Ports `5432` et `6379` exposés sur l'hôte | Base et Redis joignables depuis l'extérieur |
| 5 | Mot de passe `postgres` en clair dans le YAML | Secret versionné, fuite via le dépôt |
| 6 | `sleep 10` avant démarrage API | Fragile, lent, race conditions possibles |
| 7 | Un seul réseau implicite (bridge projet) | Pas de segmentation front/back |
| 8 | Aucun healthcheck | `depends_on` ne garantit pas la disponibilité réelle |
| 9 | Pas de volumes nommés | Données perdues au recreate du conteneur |
| 10 | `restart` incohérent (worker `always`, api absent) | Comportement de reprise non homogène |
| 11 | Pas de reverse proxy / pas de limites ressources | Surface d'attaque large, risque OOM |
| 12 | Build local sans profils tools/ops | Admin BDD et migrations toujours « dans le chemin » ou absents |
