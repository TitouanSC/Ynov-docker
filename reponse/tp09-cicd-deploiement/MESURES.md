# Mesures zéro-downtime

## Déploiement naïf

```bash
# terminal 1
./deploy/measure-downtime.sh
# terminal 2
docker compose up -d --force-recreate api
```

Résultat typique : **N échecs > 0** (conteneur unique coupé pendant recreate).

## Rolling update

```bash
./deploy/measure-downtime.sh &
./deploy/rolling-update.sh
```

Objectif : **FAIL=0** (réplicas ≥ 2 + healthcheck Traefik + SIGTERM + stop -t 15).

## Briques

| Brique | Rôle si absente |
|--------|-----------------|
| HEALTHCHECK image | Traefik/compose peut router vers instance morte |
| `--wait` / start_period | Faux ready trop tôt |
| SIGTERM / stop_grace | Coupures mid-request |
| réplicas ≥ 2 | Single point of failure pendant update |
| proxy health | Sticky traffic vers instance down |
