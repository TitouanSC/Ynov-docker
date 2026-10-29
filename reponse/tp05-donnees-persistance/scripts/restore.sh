#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
SRC="${1:?usage: restore.sh backups/YYYYMMDD-HHMMSS}"
COMPOSE="${COMPOSE:-docker compose -f compose.yml}"
[[ -f "$SRC/shop.dump" ]] || { echo "missing $SRC/shop.dump"; exit 1; }

$COMPOSE up -d --wait
# attendre init
sleep 2
$COMPOSE cp "$SRC/shop.dump" db:/tmp/shop.dump
# vider le schéma public puis restore
$COMPOSE exec -T db psql -U shop -d shop -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public; GRANT ALL ON SCHEMA public TO shop;"
$COMPOSE exec -T db pg_restore -U shop -d shop --no-owner --role=shop /tmp/shop.dump
echo "== checksum =="
$COMPOSE exec -T db psql -U shop -d shop -c \
  "SELECT count(*) AS orders, md5(string_agg(id::text || status, ',' ORDER BY id)) AS checksum FROM orders;"
echo "OK restore from $SRC"
