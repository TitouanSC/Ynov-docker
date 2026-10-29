#!/usr/bin/env bash
# upgrade-pg.sh — PostgreSQL 14 → 16 via dump/restore sur nouveau volume
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
COMPOSE="docker compose -f compose.yml"
WORKDIR="$ROOT/backups/upgrade-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$WORKDIR"

echo "== checksum AVANT (PG14) =="
$COMPOSE up -d --wait
BEFORE=$($COMPOSE exec -T db psql -U shop -d shop -Atc \
  "SELECT count(*) || '|' || md5(string_agg(id::text || status, ',' ORDER BY id)) FROM orders;")
echo "BEFORE=$BEFORE" | tee "$WORKDIR/before.txt"

echo "== dumpall + dump -Fc =="
$COMPOSE exec -T db pg_dumpall -U shop -f /tmp/all.sql
$COMPOSE exec -T db pg_dump -U shop -d shop -Fc -f /tmp/shop.dump
$COMPOSE cp db:/tmp/all.sql "$WORKDIR/all.sql"
$COMPOSE cp db:/tmp/shop.dump "$WORKDIR/shop.dump"

echo "== stop PG14 (volume conservé comme rollback) =="
$COMPOSE stop db

echo "== PG16 sur nouveau volume =="
cat > "$WORKDIR/compose.pg16.yml" <<'YAML'
name: shopdata16
services:
  db:
    image: postgres:16.4-alpine
    environment:
      POSTGRES_USER: shop
      POSTGRES_PASSWORD: shop
      POSTGRES_DB: shop
    volumes:
      - pgdata16:/var/lib/postgresql/data
    ports: ["5434:5432"]
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U shop"]
      interval: 5s
      retries: 10
volumes:
  pgdata16:
YAML

docker compose -f "$WORKDIR/compose.pg16.yml" up -d --wait
docker compose -f "$WORKDIR/compose.pg16.yml" cp "$WORKDIR/shop.dump" db:/tmp/shop.dump
docker compose -f "$WORKDIR/compose.pg16.yml" exec -T db \
  pg_restore -U shop -d shop --no-owner --role=shop /tmp/shop.dump || true

AFTER=$(docker compose -f "$WORKDIR/compose.pg16.yml" exec -T db psql -U shop -d shop -Atc \
  "SELECT count(*) || '|' || md5(string_agg(id::text || status, ',' ORDER BY id)) FROM orders;")
echo "AFTER=$AFTER" | tee "$WORKDIR/after.txt"

if [[ "$BEFORE" == "$AFTER" ]]; then
  echo "VERDICT: OK checksums identiques"
else
  echo "VERDICT: FAIL before=$BEFORE after=$AFTER" >&2
  exit 1
fi

echo "Rollback: docker compose -f compose.yml start db  (volume PG14 intact)"
echo "Travail dans $WORKDIR"
