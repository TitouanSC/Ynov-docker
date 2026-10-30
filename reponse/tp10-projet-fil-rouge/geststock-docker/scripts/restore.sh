#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${1:?usage: restore.sh backups/STAMP}"
cd "$ROOT"
docker compose up -d --wait
docker compose exec -T db sh -c 'mariadb -u root -p"$(cat /run/secrets/db_root_password)" geststock' < "$SRC/geststock.sql"
echo "OK restore $SRC"
