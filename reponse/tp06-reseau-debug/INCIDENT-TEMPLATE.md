# Rapport d'incident — préprod Shop SAS

**Heure de début** : 09:12 · **Heure de résolution** : 09:45 · **Impact** : préprod indisponible

## Chronologie du diagnostic

| Heure | Symptôme observé | Commande / preuve | Hypothèse | Résultat |
|-------|------------------|-------------------|-----------|----------|
| 09:12 | `curl :8081/products` échoue | `curl -v localhost:8081/products` | front down / mauvais upstream | 502 / connection refused selon étape |
| 09:15 | nginx proxy vers `localhost:3000` | `cat nginx/default.conf` | upstream devrait être le service `api` | Confirmé : bug conf |
| 09:18 | API `DATABASE_URL` host `databse` | `docker compose config` | typo DNS | Confirmé |
| 09:20 | API pas sur réseau `backend` | `docker inspect api` networks | ne peut joindre db | Confirmé |
| 09:22 | Redis en `network_mode: host` + mdp | compose + REDIS_URL | API ne trouve pas `redis` | Confirmé |
| 09:25 | `public.internal: true` | network inspect | pas nécessaire pour pub port ; complique | Corrigé |
| 09:28 | healthcheck `pg_isready -U postgres` | logs db health | user réel = shop | Confirmé |
| 09:30 | `command: node server.js` | Dockerfile CMD | mauvais chemin | Confirmé → `src/server.js` |
| 09:32 | `container_name` + replicas | compose | empêche scale / DNS | Retiré |
| 09:35 | paths `solution/apps` inexistants | ls | build cassé | Pointé vers tp04 apps |

## Anomalies trouvées (≥10)

| # | Fichier / service | Anomalie | Correction | Catégorie |
|---|-------------------|----------|------------|----------|
| 1 | nginx/default.conf | `proxy_pass http://localhost:3000` | `http://api:3000` | réseau |
| 2 | api env | host `databse` | `db` | config |
| 3 | api networks | absente de `backend` | `public` + `backend` | réseau |
| 4 | redis | `network_mode: host` | réseau `backend` | réseau |
| 5 | redis | `--requirepass` vs URL sans mdp | redis sans mdp lab / URL alignée | config |
| 6 | networks.public | `internal: true` inutile ici | retiré | réseau |
| 7 | db healthcheck | `-U postgres` | `-U shop` | config |
| 8 | api command | `node server.js` | image CMD / `src/server.js` | config |
| 9 | api PORT | 8080 vs proxy 3000 | PORT=3000 | config |
| 10 | build path | `solution/apps/...` | `../tp04-compose-entreprise/apps/shopapi` | cycle de vie |
| 11 | init.sql path | chemin starter cassé | bind tp04 `db/init.sql` | stockage |
| 12 | api | `container_name` + deploy.replicas | retiré | cycle de vie |

## Pourquoi ça n'a pas été détecté avant ?

Pas de `docker compose config` ni smoke test en CI ; revue compose absente ; healthchecks incorrects (faux positifs).

## Actions de prévention

1. CI : `docker compose config` + smoke `curl /products` + `--wait`
2. Revue de code obligatoire sur les diffs `compose.yml` / nginx
3. Healthchecks alignés user/DB + lint Compose (hadolint-like / docker compose)
