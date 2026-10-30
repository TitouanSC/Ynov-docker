#!/usr/bin/env bash
# Rolling update API : un réplica à la fois, Traefik ne route que healthy
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SHOP="${SHOP:-$ROOT/shop}"
cd "$SHOP"
COMPOSE="${COMPOSE:-docker compose -f compose.yml -f compose.prod.yml}"
SERVICE="${SERVICE:-api}"
VERSION="${VERSION:-local}"

echo "== scale $SERVICE to 2 =="
$COMPOSE up -d --scale "$SERVICE=2" --no-recreate --wait || \
  docker compose up -d --scale "$SERVICE=2" --wait

echo "== recreate one replica at a time =="
ids=($($COMPOSE ps -q "$SERVICE"))
for id in "${ids[@]}"; do
  name=$(docker inspect -f '{{.Name}}' "$id" | sed 's#^/##')
  echo "→ recreate $name (VERSION=$VERSION)"
  docker stop -t 15 "$id"
  docker rm "$id"
  $COMPOSE up -d --no-deps --scale "$SERVICE=${#ids[@]}" --wait
  # attendre healthy
  for i in $(seq 1 30); do
    unhealthy=$($COMPOSE ps "$SERVICE" | grep -c unhealthy || true)
    [[ "$unhealthy" == "0" ]] && break
    sleep 1
  done
done

echo "OK rolling-update VERSION=$VERSION"
echo "Rollback: VERSION=<ancien> $0"
