# Transcript — restauration & montée de version

## Seed

```
orders | checksum
100000 | 053258a3f3e7e9acc530607eff4c8c11
```

## Restore après `down -v`

```
OK restore from backups/20261029-092301/
orders | 100000 | 053258a3f3e7e9acc530607eff4c8c11
```

Checksums **identiques**.

## Changement de tag 14 → 16 (échec attendu)

```
FATAL: database files are incompatible with server
DETAIL: The data directory was initialized by PostgreSQL version 14,
        which is not compatible with this version 16.4.
```

## upgrade-pg.sh

```
BEFORE=100000|053258a3f3e7e9acc530607eff4c8c11
AFTER=100000|053258a3f3e7e9acc530607eff4c8c11
VERDICT: OK checksums identiques
```

Rollback : volume PG14 conservé (`compose start db`).

## Redis (réponses)

- `--save 60 1` : RDB périodique → perte max ≈ intervalle depuis dernier save.
- `--appendonly yes` : AOF → perte max ≈ 1 s (fsync default).
- Chez Shop : Redis = cache + file `orders:queue` → AOF ou RDB fréquent justifié pour la file ; le cache est jetable.
