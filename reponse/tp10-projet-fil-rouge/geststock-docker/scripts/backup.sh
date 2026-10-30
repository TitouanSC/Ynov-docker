#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
STAMP=$(date +%Y%m%d-%H%M%S)
OUT="$ROOT/backups/$STAMP"
mkdir -p "$OUT"
docker compose exec -T db sh -c 'mariadb-dump -u root -p"$(cat /run/secrets/db_root_password)" geststock' > "$OUT/geststock.sql"
docker run --rm -v geststock_uploads:/data:ro -v "$OUT:/out" alpine:3.20 tar czf /out/uploads.tar.gz -C /data .
echo "OK $OUT"
