#!/usr/bin/env bash
# Rejoue localement les étapes CI contre un registre local (TP03) ou images locales
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
SHOP="$ROOT/shop"
cd "$SHOP"

echo "== hadolint =="
docker run --rm -i hadolint/hadolint hadolint - --failure-threshold warning < apps/shopapi/Dockerfile

echo "== compose config =="
docker compose config >/dev/null

echo "== build test/api/worker =="
docker build -t shopapi:ci ./apps/shopapi
docker build -t shop-worker:ci ./apps/shop-worker

echo "== trivy (HIGH/CRITICAL) =="
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:0.56.2 \
  image --severity HIGH,CRITICAL --ignore-unfixed --exit-code 0 shopapi:ci || true

echo "== smoke stack =="
cp -n secrets/db_password.txt.example secrets/db_password.txt 2>/dev/null || true
[[ -f secrets/db_password.txt ]] || echo 'ci-local-pass' > secrets/db_password.txt
docker compose up -d --build --wait
./scripts/smoke-test.sh
docker compose down

echo "OK ci-local"
