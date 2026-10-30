#!/usr/bin/env bash
# Simule la migration dump SQL + uploads depuis le legacy
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
docker compose up -d --wait
# schema déjà appliqué via init ; on ajoute des données « legacy »
docker compose exec -T db sh -c 'mariadb -u geststock -p"$(cat /run/secrets/db_password)" geststock' <<'SQL'
INSERT INTO items(name, qty) VALUES ('Legacy tournevis', 7), ('Legacy carton', 1)
ON DUPLICATE KEY UPDATE qty=VALUES(qty);
SQL
mkdir -p uploads-legacy && echo 'fake-photo' > uploads-legacy/legacy.jpg
docker run --rm -v geststock_uploads:/data -v "$ROOT/uploads-legacy:/in:ro" alpine:3.20 \
  sh -c 'cp /in/* /data/ && chown -R 33:33 /data'
echo "OK migration simulée"
