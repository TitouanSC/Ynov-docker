# DIAGNOSTIC — shopapi:legacy

Preuves collectées le 26/10/2026 sur l'image `shopapi:legacy` construite depuis le Dockerfile historique.

## Taille / performance

| # | Problème | Preuve | Impact |
|---|----------|--------|--------|
| 1 | Image > 1 Go | `docker image ls shopapi:legacy` → **1.06GB** (CONTENT SIZE 279MB) | Saturation du registre, pulls CI/prod lents |
| 2 | Base Ubuntu + build-essential/vim/git | `docker history` : couche `apt-get install … build-essential` **379MB** + nodejs **173MB** | Outils de debug/build inutiles en runtime |
| 3 | Pas de multi-stage / deps de dev | `npm install` sans `--omit=dev` + `nodemon` global (**7.54MB**) ; `NODE_ENV=development` | Image gonflée, surface d'attaque élargie |
| 4 | Cache invalidé à chaque changement de code | `COPY . /app` **avant** `npm install` | Un commit README relance ≈ 4 min d'`npm install` |
| 5 | Couches apt non nettoyées / non fusionnées | hadolint DL3009, DL3059 ; `apt-get update` seul (**80.7MB**) | Listes apt et couches redondantes |

## Sécurité

| # | Problème | Preuve | Impact |
|---|----------|--------|--------|
| 6 | Conteneur root | `docker run --rm shopapi:legacy id` → `uid=0(root)` | Escalade de privilèges si RCE |
| 7 | Secret DB dans l'image (ENV) | `docker run … env \| grep` → `DATABASE_URL=…S3cret!…` ; visible aussi dans `docker history` | Fuite credentials via registry/history |
| 8 | Fichier `.env` dans l'image | `ls -la /app` → `.env` avec `AWS_SECRET_ACCESS_KEY=AKIA…` | Secrets de dev embarqués, détectables par scanner |
| 9 | Dump SQL prod dans l'image | `ls -la /app` → `dump-prod-2024.sql` | Fuite de données / schéma métier |
| 10 | hadolint warnings (versions non épinglées, CMD shell) | `hadolint` : DL3008, DL3016, DL3025, DL4006… | Image non conforme au référentiel interne |

## Exploitabilité / ops

| # | Problème | Preuve | Impact |
|---|----------|--------|--------|
| 11 | `CMD` en forme shell | Dockerfile `CMD npm start` ; history `CMD ["/bin/sh" "-c" "npm start"]` | PID 1 = shell : SIGTERM mal transmis → rolling updates lents |
| 12 | Pas de HEALTHCHECK / labels OCI | `docker inspect` sans Healthcheck ni `org.opencontainers.image.*` | Orchestreurs ne détectent pas l'état ; traçabilité absente |
| 13 | Pas de `.dockerignore` | `COPY . /app` inclut `.env`, dump, Dockerfile, tests | Contenu sensible et inutile dans l'image |

### Sortie hadolint (extrait)

```
DL3008 warning: Pin versions in apt get install
DL4006 warning: Set the SHELL option -o pipefail
DL3016 warning: Pin versions in npm
DL3025 warning: Use arguments JSON notation for CMD
```

### Pourquoi `npm install` est rejoué (étape 2)

Ordre actuel des couches : `COPY .` → `RUN npm install`. Toute modification sous `/app` (ex. `src/server.js`) invalide le checksum de `COPY`, donc toutes les couches suivantes, y compris `npm install`.

**Ordre idéal** : copier `package.json` (+ lock) → `npm ci --omit=dev` → copier le code source.
