#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
echo "== php -l =="
docker run --rm -v "$PWD/app:/app" php:8.3-cli bash -lc 'find /app -name "*.php" -print0 | xargs -0 -n1 php -l'
echo "== build + up =="
echo 'gest-pass' > secrets/db_password.txt
echo 'gest-root' > secrets/db_root_password.txt
# reset volumes : MariaDB n'applique MYSQL_*_FILE qu'à l'init
docker compose down -v --remove-orphans >/dev/null 2>&1 || true
docker compose up -d --build --wait
echo "== curl health =="
curl -sf "http://127.0.0.1:8083/?health" | grep -q OK
curl -sf "http://127.0.0.1:8083/" | grep -q GestStock
echo "== rapport on-demand =="
docker compose --profile ops run --rm rapport | grep -q Articles
docker compose down
echo OK
