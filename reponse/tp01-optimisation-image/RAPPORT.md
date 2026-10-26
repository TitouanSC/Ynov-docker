# RAPPORT — TP01 shopapi

## Tableau avant / après

| Métrique | Legacy | Optimisé (`shopapi:1.4.2`) |
|----------|--------|----------------------------|
| Taille (`docker image inspect .Size`) | ~1.06 Go (disk usage) | **50 140 442 o ≈ 47,8 Mio** (< 200 Mo) |
| Couches applicatives utiles | `COPY .` + `npm install` monolithe | multi-stage deps / test / runtime |
| Rebuild après changement de code | `npm install` rejoué | `npm ci` **CACHED** (~1,2 s) |
| Utilisateur | `uid=0(root)` | `uid=1000(node)` |
| Secrets / dumps dans l'image | `.env`, `dump-prod-2024.sql`, `DATABASE_URL` | absents (`.dockerignore` + pas d'ENV secret) |
| HEALTHCHECK | aucun | `healthy` après ~6 s |
| Arrêt (`docker stop`) | shell form `CMD npm start` | **0,16 s** (SIGTERM → `server.close`) |
| Labels OCI | absents | version, revision, source, title |
| hadolint warning/error | plusieurs (DL3008, DL3025…) | **sortie vide** (`--failure-threshold warning`) |

## Pourquoi le stop legacy peut être lent

Avec `CMD npm start` (forme shell), PID 1 est `/bin/sh`. `SIGTERM` arrive au shell qui ne le relaie pas toujours à Node → Docker attend le timeout (~10 s) puis envoie `SIGKILL`. La forme exec `CMD ["node","src/server.js"]` fait de Node le PID 1 : les handlers `SIGTERM`/`SIGINT` du code applicatif s'exécutent immédiatement.

## Dockerfile final

Voir `shopapi/Dockerfile` (+ `shopapi/.dockerignore`).

## hadolint

```bash
docker run --rm -i hadolint/hadolint hadolint - --failure-threshold warning < Dockerfile
# (aucune sortie)
```

## Ordre des couches idéal (cache)

```
package.json + package-lock.json
        ↓
   npm ci --omit=dev     ← invalidé seulement si les deps changent
        ↓
   COPY src/             ← changement de code : deps restent en cache
        ↓
   USER / HEALTHCHECK / CMD exec
```
