# TP07 — Notes

## Logs Docker

Sans `max-size`, le json-file grossit indéfiniment (disque plein). Les apps doivent loguer sur stdout/stderr pour que le runtime collecte. Drivers : `json-file` / `local` / `journald` / `fluentd` / `awslogs`. `mode: non-blocking` + `max-buffer-size` : évite de bloquer l'app si le logging est lent (perte possible).

## Pourquoi pas `docker_sd_configs` dans Prometheus ?

Prometheus image officielle tourne souvent non-root et n'a pas accès au socket Docker ; `dns_sd_configs` sur le nom DNS Compose `api` scrape tous les réplicas sans privilège.

## Démarrage

```bash
# stack shop (TP04) déjà up → réseaux shop_front / shop_back
docker compose -f compose.observability.yml up -d
./load.sh 1000
open http://localhost:9090/targets
open http://localhost:3001   # admin/admin
```
