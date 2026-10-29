# Étape 1 — Anatomie du stockage

## Writable layer vs volume

- `docker exec db touch /tmp/x` puis `docker diff` → `A /tmp/x` : fichier dans la **writable layer** du conteneur.
- Les données Postgres sont sur le volume nommé `shop_pgdata` monté sur `/var/lib/postgresql/data` (`docker inspect` → Type `volume`).

## Que deviennent les volumes ?

| Commande | Volume nommé `pgdata` |
|----------|------------------------|
| `compose down` | **Conservé** |
| `compose down -v` | **Supprimé** |
| `compose rm` | Conteneurs seulement ; volume intact |
| `docker volume prune` | Supprime les volumes **non utilisés** |

## Volume anonyme

`docker run -d postgres:16-alpine` sans `-v` crée un volume anonyme. `docker rm` le laisse orphelin ; `docker rm -v` le supprime. Piège : fausse impression de persistance.

## Bind / volume nommé / tmpfs

- **Bind** : code source, configs (dev) — perf variables sur Docker Desktop.
- **Volume nommé** : données DB/Redis (prod) — géré par Docker.
- **tmpfs** : secrets éphémères, caches — RAM only.

## Pourquoi `init.sql` n'est pas rejoué ?

L'entrypoint Postgres n'exécute `/docker-entrypoint-initdb.d` que si le data dir est **vide**. Forcer : `down -v` puis `up`, ou nouveau volume.
