#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
COMPOSE="${COMPOSE:-docker compose -f compose.yml}"
BACKUP_DIR="${BACKUP_DIR:-$ROOT/backups}"
KEEP="${KEEP:-7}"
STAMP=$(date +%Y%m%d-%H%M%S)
OUT="$BACKUP_DIR/$STAMP"
mkdir -p "$OUT"

echo "== backup logique (pg_dump -Fc) =="
$COMPOSE exec -T db pg_dump -U shop -d shop -Fc -f /tmp/shop.dump
$COMPOSE cp db:/tmp/shop.dump "$OUT/shop.dump"

echo "== backup volume (tar via alpine, RO) =="
VOL=$(docker volume ls -q --filter name=shopdata_pgdata | head -1)
[[ -n "$VOL" ]] || VOL=$(docker volume ls -q | grep '_pgdata$' | head -1)
docker run --rm -v "$VOL:/data:ro" -v "$OUT:/out" alpine:3.20 \
  tar czf /out/pgdata.tar.gz -C /data .

echo "$STAMP" > "$OUT/TIMESTAMP"
echo "== rétention keep=$KEEP =="
ls -1dt "$BACKUP_DIR"/*/ 2>/dev/null | tail -n +$((KEEP + 1)) | while read -r d; do rm -rf "$d"; done
echo "OK backup → $OUT"
